package Google::Actions::Sdk::V2::Conversation::List;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2xp
c3QucHJvdG8SImdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24inwEKBExpc3QS
FAoFdGl0bGUYASABKAlSBXRpdGxlEhoKCHN1YnRpdGxlGAIgASgJUghzdWJ0aXRsZRJHCgVp
dGVtcxgDIAMoCzIxLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24uTGlzdC5M
aXN0SXRlbVIFaXRlbXMaHAoITGlzdEl0ZW0SEAoDa2V5GAEgASgJUgNrZXlChQEKJmNvbS5n
b29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uQglMaXN0UHJvdG9QAVpOZ29vZ2xl
LmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9hY3Rpb25zL3Nkay92Mi9jb252ZXJz
YXRpb247Y29udmVyc2F0aW9uSsQJCgYSBA4AKAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQg
MjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBW
ZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxl
IGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFp
biBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3Jn
L2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUg
bGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5k
ZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJ
VEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhw
cmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFu
Z3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhl
IExpY2Vuc2UuCgoICgECEgMQACsKCAoBCBIDEgBlCgkKAggLEgMSAGUKCAoBCBIDEwAiCgkK
AggKEgMTACIKCAoBCBIDFAAqCgkKAggIEgMUACoKCAoBCBIDFQA/CgkKAggBEgMVAD8KRQoC
BAASBBgAKAEaOSBBIGNhcmQgZm9yIHByZXNlbnRpbmcgYSBsaXN0IG9mIG9wdGlvbnMgdG8g
c2VsZWN0IGZyb20uCgoKCgMEAAESAxgIDAojCgQEAAMAEgQaAh4DGhUgQW4gaXRlbSBpbiB0
aGUgbGlzdAoKDAoFBAADAAESAxoKEgpfCgYEAAMAAgASAx0EExpQIFJlcXVpcmVkLiBUaGUg
TkxVIGtleSB0aGF0IG1hdGNoZXMgdGhlIGVudHJ5IGtleSBuYW1lIGluIHRoZSBhc3NvY2lh
dGVkCiBUeXBlLgoKDgoHBAADAAIABRIDHQQKCg4KBwQAAwACAAESAx0LDgoOCgcEAAMAAgAD
EgMdERIKKwoEBAACABIDIQITGh4gVGl0bGUgb2YgdGhlIGxpc3QuIE9wdGlvbmFsLgoKDAoF
BAACAAUSAyECCAoMCgUEAAIAARIDIQkOCgwKBQQAAgADEgMhERIKLgoEBAACARIDJAIWGiEg
U3VidGl0bGUgb2YgdGhlIGxpc3QuIE9wdGlvbmFsLgoKDAoFBAACAQUSAyQCCAoMCgUEAAIB
ARIDJAkRCgwKBQQAAgEDEgMkFBUKHQoEBAACAhIDJwIeGhAgbWluOiAyIG1heDogMzAKCgwK
BQQAAgIEEgMnAgoKDAoFBAACAgYSAycLEwoMCgUEAAICARIDJxQZCgwKBQQAAgIDEgMnHB1i
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::List::List ===
    # Fields for List
    # Field: title Type: 9 ()
    # Field: subtitle Type: 9 ()
    # Field: items Type: 11 (.google.actions.sdk.v2.conversation.List.ListItem)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::List - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/list.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::List;

    my $msg = Google::Actions::Sdk::V2::Conversation::List::List->new({
        title => $title,
        subtitle => $subtitle,
        items => $items,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::List::List->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/list.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::List::List

A card for presenting a list of options to select from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Title of the list. Optional.

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

Subtitle of the list. Optional.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::List::List::ListItem>)

min: 2 max: 30

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::List::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
