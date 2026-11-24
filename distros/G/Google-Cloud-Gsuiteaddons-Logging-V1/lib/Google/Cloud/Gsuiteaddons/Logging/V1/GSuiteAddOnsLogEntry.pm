package Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CkRnb29nbGUvY2xvdWQvZ3N1aXRlYWRkb25zL2xvZ2dpbmcvdjEvZ19zdWl0ZV9hZGRfb25z
X2xvZ19lbnRyeS5wcm90bxIkZ29vZ2xlLmNsb3VkLmdzdWl0ZWFkZG9ucy5sb2dnaW5nLnYx
Ghdnb29nbGUvcnBjL3N0YXR1cy5wcm90byKRAQoUR1N1aXRlQWRkT25zTG9nRW50cnkSHgoK
ZGVwbG95bWVudBgBIAEoCVIKZGVwbG95bWVudBIoCgVlcnJvchgCIAEoCzISLmdvb2dsZS5y
cGMuU3RhdHVzUgVlcnJvchIvChNkZXBsb3ltZW50X2Z1bmN0aW9uGAMgASgJUhJkZXBsb3lt
ZW50RnVuY3Rpb25ChAIKKGNvbS5nb29nbGUuY2xvdWQuZ3N1aXRlYWRkb25zLmxvZ2dpbmcu
djFCGUdTdWl0ZUFkZE9uc0xvZ0VudHJ5UHJvdG9QAVpCY2xvdWQuZ29vZ2xlLmNvbS9nby9n
c3VpdGVhZGRvbnMvbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiqgIkR29vZ2xl
LkNsb3VkLkdTdWl0ZUFkZE9ucy5Mb2dnaW5nLlYxygIkR29vZ2xlXENsb3VkXEdTdWl0ZUFk
ZE9uc1xMb2dnaW5nXFYx6gIoR29vZ2xlOjpDbG91ZDo6R1N1aXRlQWRkT25zOjpMb2dnaW5n
OjpWMUqtDAoGEgQOACwBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAtCgkKAgMAEgMSACEKCAoBCBIDFABBCgkKAgglEgMUAEEKCAoBCBIDFQBZCgkKAggL
EgMVAFkKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA6CgkKAggIEgMXADoKCAoBCBID
GABBCgkKAggBEgMYAEEKCAoBCBIDGQBCCgkKAggpEgMZAEIKCAoBCBIDGgBBCgkKAggtEgMa
AEEK0QEKAgQAEgQfACwBGsQBIEpTT04gcGF5bG9hZCBvZiBlcnJvciBtZXNzYWdlcyB0aGF0
IGFyZSBsb2dnZWQgdG8gQ2xvdWQgTG9nZ2luZy4gQW4gZXJyb3IKIG1lc3NhZ2UgKGluIEVu
Z2xpc2gpIGlzIHdyaXR0ZW4gdG8gQ2xvdWQgTG9nZ2luZyAoaWYgbm90IGRpc2FibGVkKSB3
aGVuIGFuCiBlcnJvciBpcyBlbmNvdW50ZXJlZCB3aGlsZSB1c2luZyBhbiBhZGQtb24uCgoK
CgMEAAESAx8IHArkAQoEBAACABIDIwIYGtYBIFRoZSBkZXBsb3ltZW50IHRoYXQgY2F1c2Vk
IHRoZSBlcnJvci4gRm9yIGFkZC1vbnMgYnVpbHQgaW4gQXBwcyBTY3JpcHQsCiB0aGlzIGlz
IHRoZSBkZXBsb3ltZW50IElEIGRlZmluZWQgYnkgQXBwcyBTY3JpcHQuIEZvciBhZGQtb25z
IGJ1aWx0IGluCiBvdGhlciBsYW5ndWFnZXMsIHRoaXMgaXMgdGhlIGRlcGxveW1lbnQgSUQg
ZGVmaW5lZCBpbiBHb29nbGUgQ2xvdWQuCgoMCgUEAAIABRIDIwIICgwKBQQAAgABEgMjCRMK
DAoFBAACAAMSAyMWFwoqCgQEAAIBEgMmAh4aHSBUaGUgZXJyb3IgY29kZSBhbmQgbWVzc2Fn
ZS4KCgwKBQQAAgEGEgMmAhMKDAoFBAACAQESAyYUGQoMCgUEAAIBAxIDJhwdCsoBCgQEAAIC
EgMrAiEavAEgVGhlIGZ1bmN0aW9uIG5hbWUgdGhhdCB3YXMgcnVubmluZyB3aGVuIHRoZSBl
cnJvciBvY2N1cnJlZC4gVGhpcyBmaWVsZAogbWlnaHQgbm90IGFsd2F5cyBiZSBzZXQsIGZv
ciBleGFtcGxlLCBpZiBhbiBlcnJvciBoYXBwZW5zIHdoZW4gZmV0Y2hpbmcgdGhlCiBsaXN0
IG9mIGluc3RhbGxlZCBhZGQtb25zIGZvciBhIHVzZXIuCgoMCgUEAAICBRIDKwIICgwKBQQA
AgIBEgMrCRwKDAoFBAACAgMSAysfIGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::GSuiteAddOnsLogEntry ===
    # Fields for GSuiteAddOnsLogEntry
    # Field: deployment Type: 9 ()
    # Field: error Type: 11 (.google.rpc.Status)
    # Field: deployment_function Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry - Compiled Protocol Buffers messages for google/cloud/gsuiteaddons/logging/v1/g_suite_add_ons_log_entry.proto

=head1 SYNOPSIS

    use Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry;

    my $msg = Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::GSuiteAddOnsLogEntry->new({
        deployment => $deployment,
        error => $error,
        deployment_function => $deployment_function,
    });

    # Read or update a field
    my $val = $msg->deployment();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::GSuiteAddOnsLogEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gsuiteaddons/logging/v1/g_suite_add_ons_log_entry.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::GSuiteAddOnsLogEntry

JSON payload of error messages that are logged to Cloud Logging. An error
message (in English) is written to Cloud Logging (if not disabled) when an
error is encountered while using an add-on.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->deployment() >> / C<< $msg->deployment($value) >>

Type: C<String>

The deployment that caused the error. For add-ons built in Apps Script,
this is the deployment ID defined by Apps Script. For add-ons built in
other languages, this is the deployment ID defined in Google Cloud.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Rpc::Status::Status>)

The error code and message.

=item * C<< $msg->deployment_function() >> / C<< $msg->deployment_function($value) >>

Type: C<String>

The function name that was running when the error occurred. This field
might not always be set, for example, if an error happens when fetching the
list of installed add-ons for a user.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gsuiteaddons::Logging::V1::GSuiteAddOnsLogEntry::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
