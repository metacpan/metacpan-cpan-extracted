package Google::Cloud::Support::V2beta::FeedItem;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Support::V2beta::Attachment };
    eval { require Google::Cloud::Support::V2beta::Comment };
    eval { require Google::Cloud::Support::V2beta::EmailMessage };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvZmVlZF9pdGVtLnByb3RvEhtnb29nbGUu
Y2xvdWQuc3VwcG9ydC52MmJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
LGdvb2dsZS9jbG91ZC9zdXBwb3J0L3YyYmV0YS9hdHRhY2htZW50LnByb3RvGilnb29nbGUv
Y2xvdWQvc3VwcG9ydC92MmJldGEvY29tbWVudC5wcm90bxovZ29vZ2xlL2Nsb3VkL3N1cHBv
cnQvdjJiZXRhL2VtYWlsX21lc3NhZ2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8ipwMKCEZlZWRJdGVtEkUKB2NvbW1lbnQYZCABKAsyJC5nb29nbGUuY2xvdWQu
c3VwcG9ydC52MmJldGEuQ29tbWVudEID4EEDSABSB2NvbW1lbnQSTgoKYXR0YWNobWVudBhl
IAEoCzInLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5BdHRhY2htZW50QgPgQQNIAFIK
YXR0YWNobWVudBJVCg1lbWFpbF9tZXNzYWdlGGYgASgLMikuZ29vZ2xlLmNsb3VkLnN1cHBv
cnQudjJiZXRhLkVtYWlsTWVzc2FnZUID4EEDSABSDGVtYWlsTWVzc2FnZRJdChJkZWxldGVk
X2F0dGFjaG1lbnQYZyABKAsyJy5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGEuQXR0YWNo
bWVudEID4EEDSABSEWRlbGV0ZWRBdHRhY2htZW50Ej4KCmV2ZW50X3RpbWUYASABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCWV2ZW50VGltZUIOCgxldmVudF9vYmpl
Y3RCygEKH2NvbS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MmJldGFCDUZlZWRJdGVtUHJvdG9Q
AVo5Y2xvdWQuZ29vZ2xlLmNvbS9nby9zdXBwb3J0L2FwaXYyYmV0YS9zdXBwb3J0cGI7c3Vw
cG9ydHBiqgIbR29vZ2xlLkNsb3VkLlN1cHBvcnQuVjJCZXRhygIbR29vZ2xlXENsb3VkXFN1
cHBvcnRcVjJiZXRh6gIeR29vZ2xlOjpDbG91ZDo6U3VwcG9ydDo6VjJiZXRhSpANCgYSBA4A
NwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwAS
AxIAKQoJCgIDARIDEwA2CgkKAgMCEgMUADMKCQoCAwMSAxUAOQoJCgIDBBIDFgApCggKAQgS
AxgAOAoJCgIIJRIDGAA4CggKAQgSAxkAUAoJCgIICxIDGQBQCggKAQgSAxoAIgoJCgIIChID
GgAiCggKAQgSAxsALgoJCgIICBIDGwAuCggKAQgSAxwAOAoJCgIIARIDHAA4CggKAQgSAx0A
OAoJCgIIKRIDHQA4CggKAQgSAx4ANwoJCgIILRIDHgA3CjkKAgQAEgQhADcBGi0gQSBmZWVk
IGl0ZW0gYXNzb2NpYXRlZCB3aXRoIGEgc3VwcG9ydCBjYXNlLgoKCgoDBAABEgMhCBAKNgoE
BAAIABIEIwIyAxooIFRoZSBvYmplY3QgY29ycmVzcG9uZGluZyB0byB0aGUgZXZlbnQuCgoM
CgUEAAgAARIDIwgUCjgKBAQAAgASAyUERhorIE91dHB1dCBvbmx5LiBBIGNvbW1lbnQgYWRk
ZWQgdG8gdGhlIGNhc2UuCgoMCgUEAAIABhIDJQQLCgwKBQQAAgABEgMlDBMKDAoFBAACAAMS
AyUWGQoMCgUEAAIACBIDJRpFCg8KCAQAAgAInAgAEgMlG0QKPwoEBAACARIDKARMGjIgT3V0
cHV0IG9ubHkuIEFuIGF0dGFjaG1lbnQgYXR0YWNoZWQgdG8gdGhlIGNhc2UuCgoMCgUEAAIB
BhIDKAQOCgwKBQQAAgEBEgMoDxkKDAoFBAACAQMSAygcHwoMCgUEAAIBCBIDKCBLCg8KCAQA
AgEInAgAEgMoIUoKTAoEBAACAhIEKwQsNBo+IE91dHB1dCBvbmx5LiBBbiBlbWFpbCBtZXNz
YWdlIHJlY2VpdmVkIGluIHJlcGx5IHRvIHRoZSBjYXNlLgoKDAoFBAACAgYSAysEEAoMCgUE
AAICARIDKxEeCgwKBQQAAgIDEgMrISQKDAoFBAACAggSAywIMwoPCggEAAICCJwIABIDLAky
CmQKBAQAAgMSBDAEMTQaViBPdXRwdXQgb25seS4gQSBkZWxldGVkIGF0dGFjaG1lbnQgdGhh
dCB1c2VkIHRvIGJlIGFzc29jaWF0ZWQgd2l0aCB0aGUKIHN1cHBvcnQgY2FzZS4KCgwKBQQA
AgMGEgMwBA4KDAoFBAACAwESAzAPIQoMCgUEAAIDAxIDMCQnCgwKBQQAAgMIEgMxCDMKDwoI
BAACAwicCAASAzEJMgpKCgQEAAIEEgQ1AjYyGjwgT3V0cHV0IG9ubHkuIFRpbWUgY29ycmVz
cG9uZGluZyB0byB0aGUgZXZlbnQgb2YgdGhpcyBpdGVtLgoKDAoFBAACBAYSAzUCGwoMCgUE
AAIEARIDNRwmCgwKBQQAAgQDEgM1KSoKDAoFBAACBAgSAzYGMQoPCggEAAIECJwIABIDNgcw
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::FeedItem::FeedItem ===
    # Fields for FeedItem
    # Field: comment Type: 11 (.google.cloud.support.v2beta.Comment)
    # Field: attachment Type: 11 (.google.cloud.support.v2beta.Attachment)
    # Field: email_message Type: 11 (.google.cloud.support.v2beta.EmailMessage)
    # Field: deleted_attachment Type: 11 (.google.cloud.support.v2beta.Attachment)
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::FeedItem - Compiled Protocol Buffers messages for google/cloud/support/v2beta/feed_item.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::FeedItem;

    my $msg = Google::Cloud::Support::V2beta::FeedItem::FeedItem->new({
        comment => $comment,
        attachment => $attachment,
        email_message => $email_message,
        deleted_attachment => $deleted_attachment,
    });

    # Read or update a field
    my $val = $msg->comment();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::FeedItem::FeedItem->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/feed_item.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::FeedItem::FeedItem

A feed item associated with a support case.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->comment() >> / C<< $msg->comment($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Comment::Comment>)

Output only. A comment added to the case.

=item * C<< $msg->attachment() >> / C<< $msg->attachment($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Attachment::Attachment>)

Output only. An attachment attached to the case.

=item * C<< $msg->email_message() >> / C<< $msg->email_message($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::EmailMessage::EmailMessage>)

Output only. An email message received in reply to the case.

=item * C<< $msg->deleted_attachment() >> / C<< $msg->deleted_attachment($value) >>

Type: C<Message> (L<Google::Cloud::Support::V2beta::Attachment::Attachment>)

Output only. A deleted attachment that used to be associated with the
support case.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time corresponding to the event of this item.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::FeedItem::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
