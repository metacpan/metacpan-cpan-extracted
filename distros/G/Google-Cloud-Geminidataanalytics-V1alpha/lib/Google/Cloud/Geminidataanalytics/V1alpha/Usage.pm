package Google::Cloud::Geminidataanalytics::V1alpha::Usage;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZ2VtaW5pZGF0YWFuYWx5dGljcy92MWFscGhhL3VzYWdlLnByb3Rv
Eihnb29nbGUuY2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MWFscGhhImYKClRva2VuVXNh
Z2USKgoRaW5wdXRfdG9rZW5fY291bnQYASABKAVSD2lucHV0VG9rZW5Db3VudBIsChJvdXRw
dXRfdG9rZW5fY291bnQYAiABKAVSEG91dHB1dFRva2VuQ291bnRCoAIKLGNvbS5nb29nbGUu
Y2xvdWQuZ2VtaW5pZGF0YWFuYWx5dGljcy52MWFscGhhQgpVc2FnZVByb3RvUAFaXmNsb3Vk
Lmdvb2dsZS5jb20vZ28vZ2VtaW5pZGF0YWFuYWx5dGljcy9hcGl2MWFscGhhL2dlbWluaWRh
dGFhbmFseXRpY3NwYjtnZW1pbmlkYXRhYW5hbHl0aWNzcGKqAihHb29nbGUuQ2xvdWQuR2Vt
aW5pRGF0YUFuYWx5dGljcy5WMUFscGhhygIoR29vZ2xlXENsb3VkXEdlbWluaURhdGFBbmFs
eXRpY3NcVjFhbHBoYeoCK0dvb2dsZTo6Q2xvdWQ6OkdlbWluaURhdGFBbmFseXRpY3M6OlYx
YWxwaGFKkQgKBhIEDgAhAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAMQoICgEIEgMSAEUKCQoCCCUSAxIARQoICgEIEgMTAHUKCQoCCAsSAxMAdQoICgEI
EgMUACIKCQoCCAoSAxQAIgoICgEIEgMVACsKCQoCCAgSAxUAKwoICgEIEgMWAEUKCQoCCAES
AxYARQoICgEIEgMXAEUKCQoCCCkSAxcARQoICgEIEgMYAEQKCQoCCC0SAxgARAo8CgIEABIE
GwAhARowIE92ZXJhbGwgdG9rZW4gdXNhZ2UgdHJhY2tpbmcgZm9yIHRoZSByZXNwb25zZS4K
CgoKAwQAARIDGwgSCkUKBAQAAgASAx0CHho4IFRoZSB0b3RhbCBudW1iZXIgb2YgaW5wdXQg
dG9rZW5zIHVzZWQgaW4gdGhpcyByZXF1ZXN0LgoKDAoFBAACAAUSAx0CBwoMCgUEAAIAARID
HQgZCgwKBQQAAgADEgMdHB0KRgoEBAACARIDIAIfGjkgVGhlIHRvdGFsIG51bWJlciBvZiBv
dXRwdXQgdG9rZW5zIHVzZWQgaW4gdGhpcyByZXF1ZXN0LgoKDAoFBAACAQUSAyACBwoMCgUE
AAIBARIDIAgaCgwKBQQAAgEDEgMgHR5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Geminidataanalytics::V1alpha::Usage::TokenUsage ===
    # Fields for TokenUsage
    # Field: input_token_count Type: 5 ()
    # Field: output_token_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Geminidataanalytics::V1alpha::Usage - Compiled Protocol Buffers messages for google/cloud/geminidataanalytics/v1alpha/usage.proto

=head1 SYNOPSIS

    use Google::Cloud::Geminidataanalytics::V1alpha::Usage;

    my $msg = Google::Cloud::Geminidataanalytics::V1alpha::Usage::TokenUsage->new({
        input_token_count => $input_token_count,
        output_token_count => $output_token_count,
    });

    # Read or update a field
    my $val = $msg->input_token_count();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Geminidataanalytics::V1alpha::Usage::TokenUsage->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/geminidataanalytics/v1alpha/usage.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Geminidataanalytics::V1alpha::Usage::TokenUsage

Overall token usage tracking for the response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->input_token_count() >> / C<< $msg->input_token_count($value) >>

Type: C<Int32>

The total number of input tokens used in this request.

=item * C<< $msg->output_token_count() >> / C<< $msg->output_token_count($value) >>

Type: C<Int32>

The total number of output tokens used in this request.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Geminidataanalytics::V1alpha::Usage::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
