package Google::Cloud::Discoveryengine::V1beta::Logging;

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
CjFnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9sb2dnaW5nLnByb3RvEiNn
b29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKQAQoTT2JzZXJ2YWJp
bGl0eUNvbmZpZxI4ChVvYnNlcnZhYmlsaXR5X2VuYWJsZWQYASABKAhCA+BBAVIUb2JzZXJ2
YWJpbGl0eUVuYWJsZWQSPwoZc2Vuc2l0aXZlX2xvZ2dpbmdfZW5hYmxlZBgCIAEoCEID4EEB
UhdzZW5zaXRpdmVMb2dnaW5nRW5hYmxlZEKTAgonY29tLmdvb2dsZS5jbG91ZC5kaXNjb3Zl
cnllbmdpbmUudjFiZXRhQgxMb2dnaW5nUHJvdG9QAVpRY2xvdWQuZ29vZ2xlLmNvbS9nby9k
aXNjb3ZlcnllbmdpbmUvYXBpdjFiZXRhL2Rpc2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVu
Z2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIjR29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2lu
ZS5WMUJldGHKAiNHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYmV0YeoCJkdvb2ds
ZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFiZXRhSvAJCgYSBA4AJwEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACwKCQoCAwASAxIAKQoJCgIDARID
EwAjCggKAQgSAxUAQAoJCgIIJRIDFQBACggKAQgSAxYAaAoJCgIICxIDFgBoCggKAQgSAxcA
IgoJCgIIChIDFwAiCggKAQgSAxgALQoJCgIICBIDGAAtCggKAQgSAxkAQAoJCgIIARIDGQBA
CggKAQgSAxoALQoJCgIIJBIDGgAtCggKAQgSAxsAQAoJCgIIKRIDGwBACggKAQgSAxwAPwoJ
CgIILRIDHAA/CjIKAgQAEgQfACcBGiYgT2JzZXJ2YWJpbGl0eSBjb25maWcgZm9yIGEgcmVz
b3VyY2UuCgoKCgMEAAESAx8IGwpYCgQEAAIAEgMhAkoaSyBPcHRpb25hbC4gRW5hYmxlcyBv
YnNlcnZhYmlsaXR5LiBJZiBgZmFsc2VgLCBhbGwgb3RoZXIgZmxhZ3MgYXJlIGlnbm9yZWQu
CgoMCgUEAAIABRIDIQIGCgwKBQQAAgABEgMhBxwKDAoFBAACAAMSAyEfIAoMCgUEAAIACBID
ISFJCg8KCAQAAgAInAgAEgMhIkgKsgEKBAQAAgESAyYCThqkASBPcHRpb25hbC4gRW5hYmxl
cyBzZW5zaXRpdmUgbG9nZ2luZy4gU2Vuc2l0aXZlIGxvZ2dpbmcgaW5jbHVkZXMgY3VzdG9t
ZXIKIGNvcmUgY29udGVudCAoZS5nLiBwcm9tcHRzLCByZXNwb25zZXMpLiBJZiBgZmFsc2Vg
LCB3aWxsIHNhbml0aXplIGFsbAogc2Vuc2l0aXZlIGZpZWxkcy4KCgwKBQQAAgEFEgMmAgYK
DAoFBAACAQESAyYHIAoMCgUEAAIBAxIDJiMkCgwKBQQAAgEIEgMmJU0KDwoIBAACAQicCAAS
AyYmTGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Logging::ObservabilityConfig ===
    # Fields for ObservabilityConfig
    # Field: observability_enabled Type: 8 ()
    # Field: sensitive_logging_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Logging - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/logging.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Logging;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Logging::ObservabilityConfig->new({
        observability_enabled => $observability_enabled,
        sensitive_logging_enabled => $sensitive_logging_enabled,
    });

    # Read or update a field
    my $val = $msg->observability_enabled();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Logging::ObservabilityConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/logging.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Logging::ObservabilityConfig

Observability config for a resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->observability_enabled() >> / C<< $msg->observability_enabled($value) >>

Type: C<Bool>

Optional. Enables observability. If `false`, all other flags are ignored.

=item * C<< $msg->sensitive_logging_enabled() >> / C<< $msg->sensitive_logging_enabled($value) >>

Type: C<Bool>

Optional. Enables sensitive logging. Sensitive logging includes customer
core content (e.g. prompts, responses). If `false`, will sanitize all
sensitive fields.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Logging::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
