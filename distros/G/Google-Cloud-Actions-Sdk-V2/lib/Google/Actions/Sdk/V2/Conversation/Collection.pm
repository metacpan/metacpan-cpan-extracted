package Google::Actions::Sdk::V2::Conversation::Collection;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Image };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2Nv
bGxlY3Rpb24ucHJvdG8SImdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24aPWdv
b2dsZS9hY3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb24vcHJvbXB0L2NvbnRlbnQvaW1hZ2Uu
cHJvdG8iiwIKCkNvbGxlY3Rpb24SFAoFdGl0bGUYASABKAlSBXRpdGxlEhoKCHN1YnRpdGxl
GAIgASgJUghzdWJ0aXRsZRJTCgVpdGVtcxgDIAMoCzI9Lmdvb2dsZS5hY3Rpb25zLnNkay52
Mi5jb252ZXJzYXRpb24uQ29sbGVjdGlvbi5Db2xsZWN0aW9uSXRlbVIFaXRlbXMSUgoKaW1h
Z2VfZmlsbBgEIAEoDjIzLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24uSW1h
Z2UuSW1hZ2VGaWxsUglpbWFnZUZpbGwaIgoOQ29sbGVjdGlvbkl0ZW0SEAoDa2V5GAEgASgJ
UgNrZXlCiwEKJmNvbS5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uQg9Db2xs
ZWN0aW9uUHJvdG9QAVpOZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9h
Y3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb247Y29udmVyc2F0aW9uSukKCgYSBA4ALQEKvAQK
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
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIARwoI
CgEIEgMUAGUKCQoCCAsSAxQAZQoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWADAKCQoC
CAgSAxYAMAoICgEIEgMXAD8KCQoCCAESAxcAPwpLCgIEABIEGgAtARo/IEEgY2FyZCBmb3Ig
cHJlc2VudGluZyBhIGNvbGxlY3Rpb24gb2Ygb3B0aW9ucyB0byBzZWxlY3QgZnJvbS4KCgoK
AwQAARIDGggSCikKBAQAAwASBBwCIAMaGyBBbiBpdGVtIGluIHRoZSBjb2xsZWN0aW9uCgoM
CgUEAAMAARIDHAoYCl8KBgQAAwACABIDHwQTGlAgUmVxdWlyZWQuIFRoZSBOTFUga2V5IHRo
YXQgbWF0Y2hlcyB0aGUgZW50cnkga2V5IG5hbWUgaW4gdGhlIGFzc29jaWF0ZWQKIFR5cGUu
CgoOCgcEAAMAAgAFEgMfBAoKDgoHBAADAAIAARIDHwsOCg4KBwQAAwACAAMSAx8REgoxCgQE
AAIAEgMjAhMaJCBUaXRsZSBvZiB0aGUgY29sbGVjdGlvbi4gT3B0aW9uYWwuCgoMCgUEAAIA
BRIDIwIICgwKBQQAAgABEgMjCQ4KDAoFBAACAAMSAyMREgo0CgQEAAIBEgMmAhYaJyBTdWJ0
aXRsZSBvZiB0aGUgY29sbGVjdGlvbi4gT3B0aW9uYWwuCgoMCgUEAAIBBRIDJgIICgwKBQQA
AgEBEgMmCREKDAoFBAACAQMSAyYUFQodCgQEAAICEgMpAiQaECBtaW46IDIgbWF4OiAxMAoK
DAoFBAACAgQSAykCCgoMCgUEAAICBhIDKQsZCgwKBQQAAgIBEgMpGh8KDAoFBAACAgMSAyki
IwpWCgQEAAIDEgMsAiEaSSBIb3cgdGhlIGltYWdlIGJhY2tncm91bmRzIG9mIGNvbGxlY3Rp
b24gaXRlbXMgd2lsbCBiZSBmaWxsZWQuIE9wdGlvbmFsLgoKDAoFBAACAwYSAywCEQoMCgUE
AAIDARIDLBIcCgwKBQQAAgMDEgMsHyBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Collection::Collection ===
    # Fields for Collection
    # Field: title Type: 9 ()
    # Field: subtitle Type: 9 ()
    # Field: items Type: 11 (.google.actions.sdk.v2.conversation.Collection.CollectionItem)
    # Field: image_fill Type: 14 (.google.actions.sdk.v2.conversation.Image.ImageFill)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Collection - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/collection.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Collection;

    my $msg = Google::Actions::Sdk::V2::Conversation::Collection::Collection->new({
        title => $title,
        subtitle => $subtitle,
        items => $items,
        image_fill => $image_fill,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Collection::Collection->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/collection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Collection::Collection

A card for presenting a collection of options to select from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Title of the collection. Optional.

=item * C<< $msg->subtitle() >> / C<< $msg->subtitle($value) >>

Type: C<String>

Subtitle of the collection. Optional.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Collection::Collection::CollectionItem>)

min: 2 max: 10

=item * C<< $msg->image_fill() >> / C<< $msg->image_fill($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::Image::ImageFill>)

How the image backgrounds of collection items will be filled. Optional.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Collection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
