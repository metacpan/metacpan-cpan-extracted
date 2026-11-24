package Google::Actions::Sdk::V2::Interactionmodel::EntitySet;

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
Cjdnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9lbnRpdHlfc2V0LnBy
b3RvEiZnb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbBofZ29vZ2xlL2Fw
aS9maWVsZF9iZWhhdmlvci5wcm90byKFAQoJRW50aXR5U2V0ElkKCGVudGl0aWVzGAEgAygL
MjguZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwuRW50aXR5U2V0LkVu
dGl0eUID4EECUghlbnRpdGllcxodCgZFbnRpdHkSEwoCaWQYASABKAlCA+BBAlICaWRClgEK
KmNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbEIORW50aXR5U2V0
UHJvdG9QAVpWZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25z
L3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsO2ludGVyYWN0aW9ubW9kZWxKqwsKBhIEDgAoAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALwoJCgIDABIDEgAp
CggKAQgSAxQAbQoJCgIICxIDFABtCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYALwoJ
CgIICBIDFgAvCggKAQgSAxcAQwoJCgIIARIDFwBDCs8BCgIEABIEHAAoARrCASBFbnRpdHkg
c2V0cyBkZXNjcmliZSB0aGUgcHJlLWRlZmluZWQgc2V0IG9mIGVudGl0aWVzIHRoYXQgdGhl
IHZhbHVlcyBvZgogYnVpbHQtaW4gaW50ZW50IHBhcmFtZXRlcnMgY2FuIGNvbWUgZnJvbS4g
RW50aXR5IHNldHMgY2FuIGJlIHJlZmVyZW5jZWQgZnJvbQogZW50aXR5X3NldCBpbiBidWls
dC1pbiBpbnRlbnQgcGFyYW1ldGVycy4KCgoKAwQAARIDHAgRCkoKBAQAAwASBB4CJAMaPCBB
biBlbnRpdHkgYSBidWlsdC1pbiBpbnRlbnQgcGFyYW1ldGVyIHZhbHVlIGNhbiBjb21lIGZy
b20uCgoMCgUEAAMAARIDHgoQCs0BCgYEAAMAAgASAyMEOxq9ASBSZXF1aXJlZC4gVGhlIElE
IG9mIHRoZSBlbnRpdHkuCiBGb3IgYSBsaXN0IG9mIGJ1aWx0LWluLWludGVudCBwYXJhbWV0
ZXJzIGFuZCB0aGVpciBzdXBwb3J0ZWQgZW50aXRpZXMsCiBzZWUKIGh0dHBzOi8vZGV2ZWxv
cGVycy5nb29nbGUuY29tL2Fzc2lzdGFudC9jb252ZXJzYXRpb25hbC9idWlsZC9idWlsdC1p
bi1pbnRlbnRzCgoOCgcEAAMAAgAFEgMjBAoKDgoHBAADAAIAARIDIwsNCg4KBwQAAwACAAMS
AyMQEQoOCgcEAAMAAgAIEgMjEjoKEQoKBAADAAIACJwIABIDIxM5CkcKBAQAAgASAycCSBo6
IFJlcXVpcmVkLiBUaGUgbGlzdCBvZiBlbnRpdGllcyB0aGlzIGVudGl0eSBzZXQgc3VwcG9y
dHMuCgoMCgUEAAIABBIDJwIKCgwKBQQAAgAGEgMnCxEKDAoFBAACAAESAycSGgoMCgUEAAIA
AxIDJx0eCgwKBQQAAgAIEgMnH0cKDwoIBAACAAicCAASAycgRmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet ===
    # Fields for EntitySet
    # Field: entities Type: 11 (.google.actions.sdk.v2.interactionmodel.EntitySet.Entity)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::EntitySet - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/entity_set.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::EntitySet;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet->new({
        entities => $entities,
    });

    # Read or update a field
    my $val = $msg->entities();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/entity_set.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet

Entity sets describe the pre-defined set of entities that the values of
built-in intent parameters can come from. Entity sets can be referenced from
entity_set in built-in intent parameters.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entities() >> / C<< $msg->entities($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::EntitySet::EntitySet::Entity>)

Required. The list of entities this entity set supports.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::EntitySet::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
