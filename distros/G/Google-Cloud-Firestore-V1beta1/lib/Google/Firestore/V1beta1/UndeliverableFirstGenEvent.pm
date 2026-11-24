package Google::Firestore::V1beta1::UndeliverableFirstGenEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvZmlyZXN0b3JlL3YxYmV0YTEvdW5kZWxpdmVyYWJsZV9maXJzdF9nZW5fZXZl
bnQucHJvdG8SGGdvb2dsZS5maXJlc3RvcmUudjFiZXRhMRofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byKvBAoaVW5kZWxpdmVyYWJsZUZpcnN0R2VuRXZlbnQSGAoHbWVzc2Fn
ZRgBIAEoCVIHbWVzc2FnZRJTCgZyZWFzb24YAiABKA4yOy5nb29nbGUuZmlyZXN0b3JlLnYx
YmV0YTEuVW5kZWxpdmVyYWJsZUZpcnN0R2VuRXZlbnQuUmVhc29uUgZyZWFzb24SIwoNZG9j
dW1lbnRfbmFtZRgDIAEoCVIMZG9jdW1lbnROYW1lEnkKFGRvY3VtZW50X2NoYW5nZV90eXBl
GAQgASgOMkcuZ29vZ2xlLmZpcmVzdG9yZS52MWJldGExLlVuZGVsaXZlcmFibGVGaXJzdEdl
bkV2ZW50LkRvY3VtZW50Q2hhbmdlVHlwZVISZG9jdW1lbnRDaGFuZ2VUeXBlEiMKDWZ1bmN0
aW9uX25hbWUYBSADKAlSDGZ1bmN0aW9uTmFtZRJBCg50cmlnZ2VyZWRfdGltZRgGIAEoCzIa
Lmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDXRyaWdnZXJlZFRpbWUiOgoGUmVhc29uEhYK
ElJFQVNPTl9VTlNQRUNJRklFRBAAEhgKFEVYQ0VFRElOR19TSVpFX0xJTUlUEAEiXgoSRG9j
dW1lbnRDaGFuZ2VUeXBlEiQKIERPQ1VNRU5UX0NIQU5HRV9UWVBFX1VOU1BFQ0lGSUVEEAAS
CgoGQ1JFQVRFEAESCgoGREVMRVRFEAISCgoGVVBEQVRFEANC6QEKHGNvbS5nb29nbGUuZmly
ZXN0b3JlLnYxYmV0YTFCH1VuZGVsaXZlcmFibGVGaXJzdEdlbkV2ZW50UHJvdG9QAVpAY2xv
dWQuZ29vZ2xlLmNvbS9nby9maXJlc3RvcmUvYXBpdjFiZXRhMS9maXJlc3RvcmVwYjtmaXJl
c3RvcmVwYqoCHkdvb2dsZS5DbG91ZC5GaXJlc3RvcmUuVjFCZXRhMcoCHkdvb2dsZVxDbG91
ZFxGaXJlc3RvcmVcVjFiZXRhMeoCIUdvb2dsZTo6Q2xvdWQ6OkZpcmVzdG9yZTo6VjFiZXRh
MUrgEQoGEgQOAEoBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAhCgkKAgMAEgMSACkKCAoBCBIDFAA7CgkKAgglEgMUADsKCAoBCBIDFQBXCgkKAggLEgMV
AFcKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwBACgkKAggIEgMXAEAKCAoBCBIDGAA1
CgkKAggBEgMYADUKCAoBCBIDGQA7CgkKAggpEgMZADsKCAoBCBIDGgA6CgkKAggtEgMaADoK
0wEKAgQAEgQfAEoBGsYBIEEgbWVzc2FnZSBzaWduaWZ5aW5nIGFuIGV2ZW50IHRoYXQgY2Fu
bm90IGJlIGRlbGl2ZXJlZCB0byBDbG91ZCBGdW5jdGlvbnMKIGZyb20gRmlyZXN0b3JlIHVz
aW5nIFtDbG91ZCBGaXJlc3RvcmUgdHJpZ2dlcnMgMXN0CiBnZW5dKGh0dHBzOi8vY2xvdWQu
Z29vZ2xlLmNvbS9mdW5jdGlvbnMvZG9jcy9jYWxsaW5nL2Nsb3VkLWZpcmVzdG9yZSkKCgoK
AwQAARIDHwgiCjYKBAQABAASBCECJwMaKCBSZWFzb24gZm9yIGV2ZW50cyBiZWluZyB1bmRl
bGl2ZXJhYmxlLgoKDAoFBAAEAAESAyEHDQodCgYEAAQAAgASAyMEGxoOIFVuc3BlY2lmaWVk
LgoKDgoHBAAEAAIAARIDIwQWCg4KBwQABAACAAISAyMZGgozCgYEAAQAAgESAyYEHRokIEV4
Y2VlZGluZyBtYXhpbXVtIGV2ZW50IHNpemUgbGltaXQKCg4KBwQABAACAQESAyYEGAoOCgcE
AAQAAgECEgMmGxwKJQoEBAAEARIEKgI2AxoXIERvY3VtZW50IGNoYW5nZSB0eXBlLgoKDAoF
BAAEAQESAyoHGQodCgYEAAQBAgASAywEKRoOIFVuc3BlY2lmaWVkLgoKDgoHBAAEAQIAARID
LAQkCg4KBwQABAECAAISAywnKAouCgYEAAQBAgESAy8EDxofIFJlcHJlc2VudCBjcmVhdGlv
biBvcGVyYXRpb24uCgoOCgcEAAQBAgEBEgMvBAoKDgoHBAAEAQIBAhIDLw0OCiwKBgQABAEC
AhIDMgQPGh0gUmVwcmVzZW50IGRlbGV0ZSBvcGVyYXRpb24uCgoOCgcEAAQBAgIBEgMyBAoK
DgoHBAAEAQICAhIDMg0OCiwKBgQABAECAxIDNQQPGh0gUmVwcmVzZW50IHVwZGF0ZSBvcGVy
YXRpb24uCgoOCgcEAAQBAgMBEgM1BAoKDgoHBAAEAQIDAhIDNQ0OCjwKBAQAAgASAzkCFRov
IEVycm9yIG1lc3NhZ2UgZm9yIGV2ZW50cyBiZWluZyB1bmRlbGl2ZXJhYmxlLgoKDAoFBAAC
AAUSAzkCCAoMCgUEAAIAARIDOQkQCgwKBQQAAgADEgM5ExQKNQoEBAACARIDPAIUGiggUmVh
c29uIGZvciBldmVudHMgYmVpbmcgdW5kZWxpdmVyYWJsZS4KCgwKBQQAAgEGEgM8AggKDAoF
BAACAQESAzwJDwoMCgUEAAIBAxIDPBITCpUBCgQEAAICEgNAAhsahwEgVGhlIHJlc291cmNl
IG5hbWUgb2YgdGhlIGNoYW5nZWQgZG9jdW1lbnQsIGluIHRoZSBmb3JtYXQgb2YKIGBwcm9q
ZWN0cy97cHJvamVjdElkfS9kYXRhYmFzZXMve2RhdGFiYXNlSWR9L2RvY3VtZW50cy97ZG9j
dW1lbnRfcGF0aH1gLgoKDAoFBAACAgUSA0ACCAoMCgUEAAICARIDQAkWCgwKBQQAAgIDEgNA
GRoKLwoEBAACAxIDQwIuGiIgVGhlIHR5cGUgb2YgdGhlIGRvY3VtZW50IGNoYW5nZS4KCgwK
BQQAAgMGEgNDAhQKDAoFBAACAwESA0MVKQoMCgUEAAIDAxIDQywtCk0KBAQAAgQSA0YCJBpA
IFRoZSBuYW1lcyBvZiB0aGUgZnVuY3Rpb25zIHRoYXQgd2VyZSBzdXBwb3NlZCB0byBiZSB0
cmlnZ2VyZWQuCgoMCgUEAAIEBBIDRgIKCgwKBQQAAgQFEgNGCxEKDAoFBAACBAESA0YSHwoM
CgUEAAIEAxIDRiIjCjwKBAQAAgUSA0kCLxovIFRoZSBjb21taXQgdGltZSBvZiB0cmlnZ2Vy
ZWQgd3JpdGUgb3BlcmF0aW9uLgoKDAoFBAACBQYSA0kCGwoMCgUEAAIFARIDSRwqCgwKBQQA
AgUDEgNJLS5iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::V1beta1::UndeliverableFirstGenEvent::UndeliverableFirstGenEvent ===
    # Fields for UndeliverableFirstGenEvent
    # Field: message Type: 9 ()
    # Field: reason Type: 14 (.google.firestore.v1beta1.UndeliverableFirstGenEvent.Reason)
    # Field: document_name Type: 9 ()
    # Field: document_change_type Type: 14 (.google.firestore.v1beta1.UndeliverableFirstGenEvent.DocumentChangeType)
    # Field: function_name Type: 9 ()
    # Field: triggered_time Type: 11 (.google.protobuf.Timestamp)

# Enum: UndeliverableFirstGenEvent::Reason
our $UndeliverableFirstGenEvent_REASON_UNSPECIFIED = 0;
our $UndeliverableFirstGenEvent_EXCEEDING_SIZE_LIMIT = 1;

# Enum: UndeliverableFirstGenEvent::DocumentChangeType
our $UndeliverableFirstGenEvent_DOCUMENT_CHANGE_TYPE_UNSPECIFIED = 0;
our $UndeliverableFirstGenEvent_CREATE = 1;
our $UndeliverableFirstGenEvent_DELETE = 2;
our $UndeliverableFirstGenEvent_UPDATE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::V1beta1::UndeliverableFirstGenEvent - Compiled Protocol Buffers messages for google/firestore/v1beta1/undeliverable_first_gen_event.proto

=head1 SYNOPSIS

    use Google::Firestore::V1beta1::UndeliverableFirstGenEvent;

    my $msg = Google::Firestore::V1beta1::UndeliverableFirstGenEvent::UndeliverableFirstGenEvent->new({
        message => $message,
        reason => $reason,
        document_name => $document_name,
        document_change_type => $document_change_type,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::V1beta1::UndeliverableFirstGenEvent::UndeliverableFirstGenEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/v1beta1/undeliverable_first_gen_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::V1beta1::UndeliverableFirstGenEvent::UndeliverableFirstGenEvent

A message signifying an event that cannot be delivered to Cloud Functions
from Firestore using [Cloud Firestore triggers 1st
gen](https://cloud.google.com/functions/docs/calling/cloud-firestore)

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Error message for events being undeliverable.

=item * C<< $msg->reason() >> / C<< $msg->reason($value) >>

Type: C<Enum> (L<Google::Firestore::V1beta1::UndeliverableFirstGenEvent::Reason>)

Reason for events being undeliverable.

=item * C<< $msg->document_name() >> / C<< $msg->document_name($value) >>

Type: C<String>

The resource name of the changed document, in the format of
`projects/{projectId}/databases/{databaseId}/documents/{document_path}`.

=item * C<< $msg->document_change_type() >> / C<< $msg->document_change_type($value) >>

Type: C<Enum> (L<Google::Firestore::V1beta1::UndeliverableFirstGenEvent::DocumentChangeType>)

The type of the document change.

=item * C<< $msg->function_name() >> / C<< $msg->function_name($value) >>

Type: C<String>

The names of the functions that were supposed to be triggered.

=item * C<< $msg->triggered_time() >> / C<< $msg->triggered_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The commit time of triggered write operation.

=back

=head3 Enum: UndeliverableFirstGenEvent::Reason

=over 4

=item * C<REASON_UNSPECIFIED> => C<0>

=item * C<EXCEEDING_SIZE_LIMIT> => C<1>

=back

=head3 Enum: UndeliverableFirstGenEvent::DocumentChangeType

=over 4

=item * C<DOCUMENT_CHANGE_TYPE_UNSPECIFIED> => C<0>

=item * C<CREATE> => C<1>

=item * C<DELETE> => C<2>

=item * C<UPDATE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::V1beta1::UndeliverableFirstGenEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
