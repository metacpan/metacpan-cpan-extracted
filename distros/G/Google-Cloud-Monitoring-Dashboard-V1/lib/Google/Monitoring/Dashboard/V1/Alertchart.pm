package Google::Monitoring::Dashboard::V1::Alertchart;

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
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvYWxlcnRjaGFydC5wcm90bxIeZ29v
Z2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIoIBCgpBbGVydENoYXJ0EhcKBG5h
bWUYASABKAlCA+BBAlIEbmFtZTpb6kFYCiVtb25pdG9yaW5nLmdvb2dsZWFwaXMuY29tL0Fs
ZXJ0UG9saWN5Ei9wcm9qZWN0cy97cHJvamVjdH0vYWxlcnRQb2xpY2llcy97YWxlcnRfcG9s
aWN5fUL4AQoiY29tLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MUIPQWxlcnRDaGFy
dFByb3RvUAFaRmNsb3VkLmdvb2dsZS5jb20vZ28vbW9uaXRvcmluZy9kYXNoYm9hcmQvYXBp
djEvZGFzaGJvYXJkcGI7ZGFzaGJvYXJkcGKqAiRHb29nbGUuQ2xvdWQuTW9uaXRvcmluZy5E
YXNoYm9hcmQuVjHKAiRHb29nbGVcQ2xvdWRcTW9uaXRvcmluZ1xEYXNoYm9hcmRcVjHqAihH
b29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpEYXNoYm9hcmQ6OlYxSrsICgYSBA4AKAEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJ
CgIDARIDEwAjCggKAQgSAxUAQQoJCgIIJRIDFQBBCggKAQgSAxYAXQoJCgIICxIDFgBdCggK
AQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAMAoJCgIICBIDGAAwCggKAQgSAxkAOwoJCgII
ARIDGQA7CggKAQgSAxoAQgoJCgIIKRIDGgBCCggKAQgSAxsAQQoJCgIILRIDGwBBCjYKAgQA
EgQeACgBGiogQSBjaGFydCB0aGF0IGRpc3BsYXlzIGFsZXJ0IHBvbGljeSBkYXRhLgoKCgoD
BAABEgMeCBIKCwoDBAAHEgQfAiIECg0KBQQAB50IEgQfAiIECpUBCgQEAAIAEgMnAjsahwEg
UmVxdWlyZWQuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBhbGVydCBwb2xpY3kuIFRoZSBm
b3JtYXQgaXM6CgogICAgIHByb2plY3RzL1tQUk9KRUNUX0lEX09SX05VTUJFUl0vYWxlcnRQ
b2xpY2llcy9bQUxFUlRfUE9MSUNZX0lEXQoKDAoFBAACAAUSAycCCAoMCgUEAAIAARIDJwkN
CgwKBQQAAgADEgMnEBEKDAoFBAACAAgSAycSOgoPCggEAAIACJwIABIDJxM5YgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Alertchart::AlertChart ===
    # Fields for AlertChart
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Alertchart - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/alertchart.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Alertchart;

    my $msg = Google::Monitoring::Dashboard::V1::Alertchart::AlertChart->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Alertchart::AlertChart->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/alertchart.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Alertchart::AlertChart

A chart that displays alert policy data.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the alert policy. The format is:

    projects/[PROJECT_ID_OR_NUMBER]/alertPolicies/[ALERT_POLICY_ID]

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Alertchart::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
