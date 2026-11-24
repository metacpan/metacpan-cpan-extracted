package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt };
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt };
    my $descriptor_b64 = <<'EOF';
ClFnb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfY29udGVudF9wcm9tcHQucHJvdG8SLWdvb2dsZS5hY3Rpb25zLnNkay52Mi5p
bnRlcmFjdGlvbm1vZGVsLnByb21wdBpOZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0
aW9ubW9kZWwvcHJvbXB0L2NvbnRlbnQvc3RhdGljX2NhcmRfcHJvbXB0LnByb3RvGltnb29n
bGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVudC9zdGF0
aWNfY29sbGVjdGlvbl9icm93c2VfcHJvbXB0LnByb3RvGlRnb29nbGUvYWN0aW9ucy9zZGsv
djIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVudC9zdGF0aWNfY29sbGVjdGlvbl9w
cm9tcHQucHJvdG8aT2dvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3By
b21wdC9jb250ZW50L3N0YXRpY19pbWFnZV9wcm9tcHQucHJvdG8aTmdvb2dsZS9hY3Rpb25z
L3Nkay92Mi9pbnRlcmFjdGlvbm1vZGVsL3Byb21wdC9jb250ZW50L3N0YXRpY19saXN0X3By
b21wdC5wcm90bxpPZ29vZ2xlL2FjdGlvbnMvc2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvcHJv
bXB0L2NvbnRlbnQvc3RhdGljX21lZGlhX3Byb21wdC5wcm90bxpPZ29vZ2xlL2FjdGlvbnMv
c2RrL3YyL2ludGVyYWN0aW9ubW9kZWwvcHJvbXB0L2NvbnRlbnQvc3RhdGljX3RhYmxlX3By
b21wdC5wcm90byLBBQoTU3RhdGljQ29udGVudFByb21wdBJVCgRjYXJkGAEgASgLMj8uZ29v
Z2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwucHJvbXB0LlN0YXRpY0NhcmRQ
cm9tcHRIAFIEY2FyZBJYCgVpbWFnZRgCIAEoCzJALmdvb2dsZS5hY3Rpb25zLnNkay52Mi5p
bnRlcmFjdGlvbm1vZGVsLnByb21wdC5TdGF0aWNJbWFnZVByb21wdEgAUgVpbWFnZRJYCgV0
YWJsZRgDIAEoCzJALmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnBy
b21wdC5TdGF0aWNUYWJsZVByb21wdEgAUgV0YWJsZRJYCgVtZWRpYRgEIAEoCzJALmdvb2ds
ZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnByb21wdC5TdGF0aWNNZWRpYVBy
b21wdEgAUgVtZWRpYRJVCgRsaXN0GAUgASgLMj8uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmlu
dGVyYWN0aW9ubW9kZWwucHJvbXB0LlN0YXRpY0xpc3RQcm9tcHRIAFIEbGlzdBJnCgpjb2xs
ZWN0aW9uGAYgASgLMkUuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwu
cHJvbXB0LlN0YXRpY0NvbGxlY3Rpb25Qcm9tcHRIAFIKY29sbGVjdGlvbhJ6ChFjb2xsZWN0
aW9uX2Jyb3dzZRgHIAEoCzJLLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1v
ZGVsLnByb21wdC5TdGF0aWNDb2xsZWN0aW9uQnJvd3NlUHJvbXB0SABSEGNvbGxlY3Rpb25C
cm93c2VCCQoHY29udGVudEKkAQoxY29tLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFj
dGlvbm1vZGVsLnByb21wdEIYU3RhdGljQ29udGVudFByb21wdFByb3RvUAFaU2dvb2dsZS5n
b2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rp
b25tb2RlbC9wcm9tcHQ7cHJvbXB0SqMMCgYSBA4AOAEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQADYKCQoCAwASAxIAWAoJCgIDARIDEwBlCgkKAgMCEgMU
AF4KCQoCAwMSAxUAWQoJCgIDBBIDFgBYCgkKAgMFEgMXAFkKCQoCAwYSAxgAWQoICgEIEgMa
AGoKCQoCCAsSAxoAagoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcADkKCQoCCAgSAxwA
OQoICgEIEgMdAEoKCQoCCAESAx0ASgpDCgIEABIEIAA4ARo3IEEgcGxhY2Vob2xkZXIgZm9y
IHRoZSBDb250ZW50IHBhcnQgb2YgYSBTdGF0aWNQcm9tcHQuCgoKCgMEAAESAyAIGwpECgQE
AAgAEgQiAjcDGjYgT25seSBvbmUgdHlwZSBvZiBjb250ZW50IGNhbiBiZSBwcmVzZW50IGlu
IGEgUHJvbXB0LgoKDAoFBAAIAAESAyIIDwocCgQEAAIAEgMkBB4aDyBBIGJhc2ljIGNhcmQu
CgoMCgUEAAIABhIDJAQUCgwKBQQAAgABEgMkFRkKDAoFBAACAAMSAyQcHQoYCgQEAAIBEgMn
BCAaCyBBbiBpbWFnZS4KCgwKBQQAAgEGEgMnBBUKDAoFBAACAQESAycWGwoMCgUEAAIBAxID
Jx4fChoKBAQAAgISAyoEIBoNIFRhYmxlIGNhcmQuCgoMCgUEAAICBhIDKgQVCgwKBQQAAgIB
EgMqFhsKDAoFBAACAgMSAyoeHwo/CgQEAAIDEgMtBCAaMiBSZXNwb25zZSBpbmRpY2F0aW5n
IGEgc2V0IG9mIG1lZGlhIHRvIGJlIHBsYXllZC4KCgwKBQQAAgMGEgMtBBUKDAoFBAACAwES
Ay0WGwoMCgUEAAIDAxIDLR4fCkYKBAQAAgQSAzAEHho5IEEgY2FyZCBmb3IgcHJlc2VudGlu
ZyBhIGxpc3Qgb2Ygb3B0aW9ucyB0byBzZWxlY3QgZnJvbS4KCgwKBQQAAgQGEgMwBBQKDAoF
BAACBAESAzAVGQoMCgUEAAIEAxIDMBwdCkIKBAQAAgUSAzMEKho1IEEgY2FyZCBwcmVzZW50
aW5nIGEgbGlzdCBvZiBvcHRpb25zIHRvIHNlbGVjdCBmcm9tLgoKDAoFBAACBQYSAzMEGgoM
CgUEAAIFARIDMxslCgwKBQQAAgUDEgMzKCkKQwoEBAACBhIDNgQ3GjYgQSBjYXJkIHByZXNl
bnRpbmcgYSBjb2xsZWN0aW9uIG9mIHdlYiBwYWdlcyB0byBvcGVuLgoKDAoFBAACBgYSAzYE
IAoMCgUEAAIGARIDNiEyCgwKBQQAAgYDEgM2NTZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::StaticContentPrompt ===
    # Fields for StaticContentPrompt
    # Field: card Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticCardPrompt)
    # Field: image Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticImagePrompt)
    # Field: table Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticTablePrompt)
    # Field: media Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticMediaPrompt)
    # Field: list Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticListPrompt)
    # Field: collection Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticCollectionPrompt)
    # Field: collection_browse Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticCollectionBrowsePrompt)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_content_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::StaticContentPrompt->new({
        card => $card,
        image => $image,
        table => $table,
        media => $media,
    });

    # Read or update a field
    my $val = $msg->card();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::StaticContentPrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_content_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::StaticContentPrompt

A placeholder for the Content part of a StaticPrompt.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->card() >> / C<< $msg->card($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCardPrompt::StaticCardPrompt>)

A basic card.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt>)

An image.

=item * C<< $msg->table() >> / C<< $msg->table($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticTablePrompt::StaticTablePrompt>)

Table card.

=item * C<< $msg->media() >> / C<< $msg->media($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::StaticMediaPrompt>)

Response indicating a set of media to be played.

=item * C<< $msg->list() >> / C<< $msg->list($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticListPrompt::StaticListPrompt>)

A card for presenting a list of options to select from.

=item * C<< $msg->collection() >> / C<< $msg->collection($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionPrompt::StaticCollectionPrompt>)

A card presenting a list of options to select from.

=item * C<< $msg->collection_browse() >> / C<< $msg->collection_browse($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticCollectionBrowsePrompt::StaticCollectionBrowsePrompt>)

A card presenting a collection of web pages to open.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticContentPrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
