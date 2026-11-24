package Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ckhnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvc3VyZmFj
ZV9jYXBhYmlsaXRpZXMucHJvdG8SLWdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlv
bm1vZGVsLnByb21wdBofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byKZAgoTU3Vy
ZmFjZUNhcGFiaWxpdGllcxJ2CgxjYXBhYmlsaXRpZXMYASADKA4yTS5nb29nbGUuYWN0aW9u
cy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHQuU3VyZmFjZUNhcGFiaWxpdGllcy5D
YXBhYmlsaXR5QgPgQQJSDGNhcGFiaWxpdGllcyKJAQoKQ2FwYWJpbGl0eRIPCgtVTlNQRUNJ
RklFRBAAEgoKBlNQRUVDSBABEhEKDVJJQ0hfUkVTUE9OU0UQAhITCg9MT05HX0ZPUk1fQVVE
SU8QAxIWChJJTlRFUkFDVElWRV9DQU5WQVMQBBIMCghXRUJfTElOSxAFEhAKDEhPTUVfU1RP
UkFHRRAGQqQBCjFjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwu
cHJvbXB0QhhTdXJmYWNlQ2FwYWJpbGl0aWVzUHJvdG9QAVpTZ29vZ2xlLmdvbGFuZy5vcmcv
Z2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3By
b21wdDtwcm9tcHRKiQ4KBhIEDgA1AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAANgoJCgIDABIDEgApCggKAQgSAxQAagoJCgIICxIDFABqCggKAQgSAxUA
IgoJCgIIChIDFQAiCggKAQgSAxYAOQoJCgIICBIDFgA5CggKAQgSAxcASgoJCgIIARIDFwBK
ClcKAgQAEgQaADUBGksgUmVwcmVzZW50cyB0aGUgc3VyZmFjZSB0aGUgdXNlciBpcyB1c2lu
ZyB0byBtYWtlIGEgcmVxdWVzdCB0byB0aGUgQWN0aW9uLgoKCgoDBAABEgMaCBsKVAoEBAAE
ABIEHAIxAxpGIENhcGFiaWxpdGllcyB0aGUgZGV2aWNlIHN1cmZhY2Ugc3VwcG9ydHMgYXQg
dGhlIHRpbWUgb2YgdGhlIHJlcXVlc3QuCgoMCgUEAAQAARIDHAcRCjAKBgQABAACABIDHgQU
GiEgVW5zcGVjaWZpZWQgc3VyZmFjZSBjYXBhYmlsaXR5LgoKDgoHBAAEAAIAARIDHgQPCg4K
BwQABAACAAISAx4SEwpJCgYEAAQAAgESAyEEDxo6IERldmljZSBjYW4gc3BlYWsgdG8gdGhl
IHVzZXIgdmlhIHRleHQtdG8tc3BlZWNoIG9yIFNTTUwuCgoOCgcEAAQAAgEBEgMhBAoKDgoH
BAAEAAIBAhIDIQ0OClAKBgQABAACAhIDJAQWGkEgRGV2aWNlIGNhbiBkaXNwbGF5IHJpY2gg
cmVzcG9uc2VzIGxpa2UgY2FyZHMsIGxpc3RzIGFuZCB0YWJsZXMuCgoOCgcEAAQAAgIBEgMk
BBEKDgoHBAAEAAICAhIDJBQVCk8KBgQABAACAxIDJwQYGkAgRGV2aWNlIGNhbiBwbGF5IGxv
bmcgZm9ybSBhdWRpbyBtZWRpYSBsaWtlIG11c2ljIGFuZCBwb2RjYXN0cy4KCg4KBwQABAAC
AwESAycEEwoOCgcEAAQAAgMCEgMnFhcKQgoGBAAEAAIEEgMqBBsaMyBEZXZpY2UgY2FuIGRp
c3BsYXkgYSBpbnRlcmFjdGl2ZSBjYW52YXMgcmVzcG9uc2UuCgoOCgcEAAQAAgQBEgMqBBYK
DgoHBAAEAAIEAhIDKhkaClIKBgQABAACBRIDLQQRGkMgRGV2aWNlIGNhbiB1c2Ugd2ViIGxp
bmtzIGluIHJpY2ggcmVzcG9uc2VzIHRvIG9wZW4gYSB3ZWIgYnJvd3Nlci4KCg4KBwQABAAC
BQESAy0EDAoOCgcEAAQAAgUCEgMtDxAKRQoGBAAEAAIGEgMwBBUaNiBEZXZpY2UgY2FuIHN1
cHBvcnQgc2F2aW5nIGFuZCBmZXRjaGluZyBob21lIHN0b3JhZ2UuCgoOCgcEAAQAAgYBEgMw
BBAKDgoHBAAEAAIGAhIDMBMUClgKBAQAAgASAzQCUBpLIFJlcXVpcmVkLiBUaGUgY2FwYWJp
bGl0aWVzIG9mIHRoZSBzdXJmYWNlIG1ha2luZyBhIHJlcXVlc3QgdG8gdGhlIEFjdGlvbi4K
CgwKBQQAAgAEEgM0AgoKDAoFBAACAAYSAzQLFQoMCgUEAAIAARIDNBYiCgwKBQQAAgADEgM0
JSYKDAoFBAACAAgSAzQnTwoPCggEAAIACJwIABIDNChOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::SurfaceCapabilities ===
    # Fields for SurfaceCapabilities
    # Field: capabilities Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.SurfaceCapabilities.Capability)

# Enum: SurfaceCapabilities::Capability
our $SurfaceCapabilities_UNSPECIFIED = 0;
our $SurfaceCapabilities_SPEECH = 1;
our $SurfaceCapabilities_RICH_RESPONSE = 2;
our $SurfaceCapabilities_LONG_FORM_AUDIO = 3;
our $SurfaceCapabilities_INTERACTIVE_CANVAS = 4;
our $SurfaceCapabilities_WEB_LINK = 5;
our $SurfaceCapabilities_HOME_STORAGE = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/surface_capabilities.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::SurfaceCapabilities->new({
        capabilities => $capabilities,
    });

    # Read or update a field
    my $val = $msg->capabilities();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::SurfaceCapabilities->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/surface_capabilities.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::SurfaceCapabilities

Represents the surface the user is using to make a request to the Action.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->capabilities() >> / C<< $msg->capabilities($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::Capability>)

Required. The capabilities of the surface making a request to the Action.

=back

=head3 Enum: SurfaceCapabilities::Capability

=over 4

=item * C<UNSPECIFIED> => C<0>

=item * C<SPEECH> => C<1>

=item * C<RICH_RESPONSE> => C<2>

=item * C<LONG_FORM_AUDIO> => C<3>

=item * C<INTERACTIVE_CANVAS> => C<4>

=item * C<WEB_LINK> => C<5>

=item * C<HOME_STORAGE> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::SurfaceCapabilities::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
