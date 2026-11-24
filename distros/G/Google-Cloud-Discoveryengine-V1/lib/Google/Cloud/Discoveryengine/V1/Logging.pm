package Google::Cloud::Discoveryengine::V1::Logging;

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
Ci1nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2xvZ2dpbmcucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8ikAEKE09ic2VydmFiaWxpdHlDb25m
aWcSOAoVb2JzZXJ2YWJpbGl0eV9lbmFibGVkGAEgASgIQgPgQQFSFG9ic2VydmFiaWxpdHlF
bmFibGVkEj8KGXNlbnNpdGl2ZV9sb2dnaW5nX2VuYWJsZWQYAiABKAhCA+BBAVIXc2Vuc2l0
aXZlTG9nZ2luZ0VuYWJsZWRC/wEKI2NvbS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5l
LnYxQgxMb2dnaW5nUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9kaXNjb3Zlcnllbmdp
bmUvYXBpdjEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKiAg9ESVNDT1ZF
UllFTkdJTkWqAh9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxygIfR29vZ2xlXENs
b3VkXERpc2NvdmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2lu
ZTo6VjFK8AkKBhIEDgAnAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
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
AQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQA8CgkKAgglEgMVADwKCAoB
CBIDFgBkCgkKAggLEgMWAGQKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAtCgkKAggI
EgMYAC0KCAoBCBIDGQA8CgkKAggBEgMZADwKCAoBCBIDGgAtCgkKAggkEgMaAC0KCAoBCBID
GwA8CgkKAggpEgMbADwKCAoBCBIDHAA7CgkKAggtEgMcADsKMgoCBAASBB8AJwEaJiBPYnNl
cnZhYmlsaXR5IGNvbmZpZyBmb3IgYSByZXNvdXJjZS4KCgoKAwQAARIDHwgbClgKBAQAAgAS
AyECShpLIE9wdGlvbmFsLiBFbmFibGVzIG9ic2VydmFiaWxpdHkuIElmIGBmYWxzZWAsIGFs
bCBvdGhlciBmbGFncyBhcmUgaWdub3JlZC4KCgwKBQQAAgAFEgMhAgYKDAoFBAACAAESAyEH
HAoMCgUEAAIAAxIDIR8gCgwKBQQAAgAIEgMhIUkKDwoIBAACAAicCAASAyEiSAqyAQoEBAAC
ARIDJgJOGqQBIE9wdGlvbmFsLiBFbmFibGVzIHNlbnNpdGl2ZSBsb2dnaW5nLiBTZW5zaXRp
dmUgbG9nZ2luZyBpbmNsdWRlcyBjdXN0b21lcgogY29yZSBjb250ZW50IChlLmcuIHByb21w
dHMsIHJlc3BvbnNlcykuIElmIGBmYWxzZWAsIHdpbGwgc2FuaXRpemUgYWxsCiBzZW5zaXRp
dmUgZmllbGRzLgoKDAoFBAACAQUSAyYCBgoMCgUEAAIBARIDJgcgCgwKBQQAAgEDEgMmIyQK
DAoFBAACAQgSAyYlTQoPCggEAAIBCJwIABIDJiZMYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Logging::ObservabilityConfig ===
    # Fields for ObservabilityConfig
    # Field: observability_enabled Type: 8 ()
    # Field: sensitive_logging_enabled Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::Logging - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/logging.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Logging;

    my $msg = Google::Cloud::Discoveryengine::V1::Logging::ObservabilityConfig->new({
        observability_enabled => $observability_enabled,
        sensitive_logging_enabled => $sensitive_logging_enabled,
    });

    # Read or update a field
    my $val = $msg->observability_enabled();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Logging::ObservabilityConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/logging.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Logging::ObservabilityConfig

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Logging::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
