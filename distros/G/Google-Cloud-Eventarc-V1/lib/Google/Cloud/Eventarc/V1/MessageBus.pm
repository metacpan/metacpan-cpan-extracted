package Google::Cloud::Eventarc::V1::MessageBus;

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
    eval { require Google::Cloud::Eventarc::V1::LoggingConfig };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvbWVzc2FnZV9idXMucHJvdG8SGGdvb2dsZS5j
bG91ZC5ldmVudGFyYy52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxotZ29vZ2xlL2Nsb3VkL2V2ZW50YXJjL3YxL2xvZ2dp
bmdfY29uZmlnLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvItoGCgpN
ZXNzYWdlQnVzEhcKBG5hbWUYASABKAlCA+BBCFIEbmFtZRIVCgN1aWQYAiABKAlCA+BBA1ID
dWlkEhcKBGV0YWcYAyABKAlCA+BBA1IEZXRhZxJACgtjcmVhdGVfdGltZRgEIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGlt
ZRgFIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJN
CgZsYWJlbHMYBiADKAsyMC5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjEuTWVzc2FnZUJ1cy5M
YWJlbHNFbnRyeUID4EEBUgZsYWJlbHMSXAoLYW5ub3RhdGlvbnMYByADKAsyNS5nb29nbGUu
Y2xvdWQuZXZlbnRhcmMudjEuTWVzc2FnZUJ1cy5Bbm5vdGF0aW9uc0VudHJ5QgPgQQFSC2Fu
bm90YXRpb25zEiYKDGRpc3BsYXlfbmFtZRgIIAEoCUID4EEBUgtkaXNwbGF5TmFtZRJRCg9j
cnlwdG9fa2V5X25hbWUYCiABKAlCKeBBAfpBIwohY2xvdWRrbXMuZ29vZ2xlYXBpcy5jb20v
Q3J5cHRvS2V5Ug1jcnlwdG9LZXlOYW1lElMKDmxvZ2dpbmdfY29uZmlnGAsgASgLMicuZ29v
Z2xlLmNsb3VkLmV2ZW50YXJjLnYxLkxvZ2dpbmdDb25maWdCA+BBAVINbG9nZ2luZ0NvbmZp
Zxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs
dWU6AjgBGj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUY
AiABKAlSBXZhbHVlOgI4ATqGAepBggEKImV2ZW50YXJjLmdvb2dsZWFwaXMuY29tL01lc3Nh
Z2VCdXMSQnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9tZXNzYWdl
QnVzZXMve21lc3NhZ2VfYnVzfSoMbWVzc2FnZUJ1c2VzMgptZXNzYWdlQnVzQr8BChxjb20u
Z29vZ2xlLmNsb3VkLmV2ZW50YXJjLnYxQg9NZXNzYWdlQnVzUHJvdG9QAVo4Y2xvdWQuZ29v
Z2xlLmNvbS9nby9ldmVudGFyYy9hcGl2MS9ldmVudGFyY3BiO2V2ZW50YXJjcGKqAhhHb29n
bGUuQ2xvdWQuRXZlbnRhcmMuVjHKAhhHb29nbGVcQ2xvdWRcRXZlbnRhcmNcVjHqAhtHb29n
bGU6OkNsb3VkOjpFdmVudGFyYzo6VjFK1RcKBhIEDgBaAQq8BAoBDBIDDgASMrEEIENvcHly
aWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vu
c2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlz
IGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkg
b2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNo
ZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGlj
YWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRl
ZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lT
LAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhl
ciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZp
YyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRl
ciB0aGUgTGljZW5zZS4KCggKAQISAxAAIQoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwIS
AxQANwoJCgIDAxIDFQApCggKAQgSAxcANQoJCgIIJRIDFwA1CggKAQgSAxgATwoJCgIICxID
GABPCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoAMAoJCgIICBIDGgAwCggKAQgSAxsA
NQoJCgIIARIDGwA1CggKAQgSAxwANQoJCgIIKRIDHAA1CggKAQgSAx0ANAoJCgIILRIDHQA0
Cp4CCgIEABIEIwBaARqRAiBNZXNzYWdlQnVzIGZvciB0aGUgbWVzc2FnZXMgZmxvd2luZyB0
aHJvdWdoIHRoZSBzeXN0ZW0uIFRoZSBhZG1pbiBoYXMKIHZpc2liaWxpdHkgYW5kIGNvbnRy
b2wgb3ZlciB0aGUgbWVzc2FnZXMgYmVpbmcgcHVibGlzaGVkIGFuZCBjb25zdW1lZCBhbmQg
Y2FuCiByZXN0cmljdCBwdWJsaXNoZXJzIGFuZCBzdWJzY3JpYmVycyB0byBvbmx5IGEgc3Vi
c2V0IG9mIGRhdGEgYXZhaWxhYmxlIGluIHRoZQogc3lzdGVtIGJ5IGRlZmluaW5nIGF1dGhv
cml6YXRpb24gcG9saWNpZXMuCgoKCgMEAAESAyMIEgoLCgMEAAcSBCQCKQQKDQoFBAAHnQgS
BCQCKQQKeAoEBAACABIDLQI9GmsgSWRlbnRpZmllci4gUmVzb3VyY2UgbmFtZSBvZiB0aGUg
Zm9ybQogcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L21lc3NhZ2VC
dXNlcy97bWVzc2FnZV9idXN9CgoMCgUEAAIABRIDLQIICgwKBQQAAgABEgMtCQ0KDAoFBAAC
AAMSAy0QEQoMCgUEAAIACBIDLRI8Cg8KCAQAAgAInAgAEgMtEzsKrwEKBAQAAgESAzICPRqh
ASBPdXRwdXQgb25seS4gU2VydmVyIGFzc2lnbmVkIHVuaXF1ZSBpZGVudGlmaWVyIGZvciB0
aGUgY2hhbm5lbC4gVGhlIHZhbHVlCiBpcyBhIFVVSUQ0IHN0cmluZyBhbmQgZ3VhcmFudGVl
ZCB0byByZW1haW4gdW5jaGFuZ2VkIHVudGlsIHRoZSByZXNvdXJjZSBpcwogZGVsZXRlZC4K
CgwKBQQAAgEFEgMyAggKDAoFBAACAQESAzIJDAoMCgUEAAIBAxIDMg8QCgwKBQQAAgEIEgMy
ETwKDwoIBAACAQicCAASAzISOwrkAQoEBAACAhIDNwI+GtYBIE91dHB1dCBvbmx5LiBUaGlz
IGNoZWNrc3VtIGlzIGNvbXB1dGVkIGJ5IHRoZSBzZXJ2ZXIgYmFzZWQgb24gdGhlIHZhbHVl
IG9mCiBvdGhlciBmaWVsZHMsIGFuZCBtaWdodCBiZSBzZW50IG9ubHkgb24gdXBkYXRlIGFu
ZCBkZWxldGUgcmVxdWVzdHMgdG8KIGVuc3VyZSB0aGF0IHRoZSBjbGllbnQgaGFzIGFuIHVw
LXRvLWRhdGUgdmFsdWUgYmVmb3JlIHByb2NlZWRpbmcuCgoMCgUEAAICBRIDNwIICgwKBQQA
AgIBEgM3CQ0KDAoFBAACAgMSAzcQEQoMCgUEAAICCBIDNxI9Cg8KCAQAAgIInAgAEgM3EzwK
LwoEBAACAxIEOgI7MhohIE91dHB1dCBvbmx5LiBUaGUgY3JlYXRpb24gdGltZS4KCgwKBQQA
AgMGEgM6AhsKDAoFBAACAwESAzocJwoMCgUEAAIDAxIDOiorCgwKBQQAAgMIEgM7BjEKDwoI
BAACAwicCAASAzsHMAo0CgQEAAIEEgQ+Aj8yGiYgT3V0cHV0IG9ubHkuIFRoZSBsYXN0LW1v
ZGlmaWVkIHRpbWUuCgoMCgUEAAIEBhIDPgIbCgwKBQQAAgQBEgM+HCcKDAoFBAACBAMSAz4q
KwoMCgUEAAIECBIDPwYxCg8KCAQAAgQInAgAEgM/BzAKKQoEBAACBRIDQgJKGhwgT3B0aW9u
YWwuIFJlc291cmNlIGxhYmVscy4KCgwKBQQAAgUGEgNCAhUKDAoFBAACBQESA0IWHAoMCgUE
AAIFAxIDQh8gCgwKBQQAAgUIEgNCIUkKDwoIBAACBQicCAASA0IiSAouCgQEAAIGEgNFAk8a
ISBPcHRpb25hbC4gUmVzb3VyY2UgYW5ub3RhdGlvbnMuCgoMCgUEAAIGBhIDRQIVCgwKBQQA
AgYBEgNFFiEKDAoFBAACBgMSA0UkJQoMCgUEAAIGCBIDRSZOCg8KCAQAAgYInAgAEgNFJ00K
LwoEBAACBxIDSAJDGiIgT3B0aW9uYWwuIFJlc291cmNlIGRpc3BsYXkgbmFtZS4KCgwKBQQA
AgcFEgNIAggKDAoFBAACBwESA0gJFQoMCgUEAAIHAxIDSBgZCgwKBQQAAgcIEgNIGkIKDwoI
BAACBwicCAASA0gbQQrMAQoEBAACCBIETwJUBBq9ASBPcHRpb25hbC4gUmVzb3VyY2UgbmFt
ZSBvZiBhIEtNUyBjcnlwdG8ga2V5IChtYW5hZ2VkIGJ5IHRoZSB1c2VyKSB1c2VkIHRvCiBl
bmNyeXB0L2RlY3J5cHQgdGhlaXIgZXZlbnQgZGF0YS4KCiBJdCBtdXN0IG1hdGNoIHRoZSBw
YXR0ZXJuCiBgcHJvamVjdHMvKi9sb2NhdGlvbnMvKi9rZXlSaW5ncy8qL2NyeXB0b0tleXMv
KmAuCgoMCgUEAAIIBRIDTwIICgwKBQQAAggBEgNPCRgKDAoFBAACCAMSA08bHQoNCgUEAAII
CBIETx5UAwoPCggEAAIICJwIABIDUAQqCg8KBwQAAggInwgSBFEEUwUKuAEKBAQAAgkSA1kC
TRqqASBPcHRpb25hbC4gQ29uZmlnIHRvIGNvbnRyb2wgUGxhdGZvcm0gbG9nZ2luZyBmb3Ig
dGhlIE1lc3NhZ2UgQnVzLiBUaGlzIGxvZwogY29uZmlndXJhdGlvbiBpcyBhcHBsaWVkIHRv
IHRoZSBNZXNzYWdlIEJ1cyBpdHNlbGYsIGFuZCBhbGwgdGhlIEVucm9sbG1lbnRzCiBhdHRh
Y2hlZCB0byBpdC4KCgwKBQQAAgkGEgNZAg8KDAoFBAACCQESA1kQHgoMCgUEAAIJAxIDWSEj
CgwKBQQAAgkIEgNZJEwKDwoIBAACCQicCAASA1klS2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::MessageBus::MessageBus ===
    # Fields for MessageBus
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.eventarc.v1.MessageBus.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.eventarc.v1.MessageBus.AnnotationsEntry)
    # Field: display_name Type: 9 ()
    # Field: crypto_key_name Type: 9 ()
    # Field: logging_config Type: 11 (.google.cloud.eventarc.v1.LoggingConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::MessageBus - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/message_bus.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::MessageBus;

    my $msg = Google::Cloud::Eventarc::V1::MessageBus::MessageBus->new({
        name => $name,
        uid => $uid,
        etag => $etag,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::MessageBus::MessageBus->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/message_bus.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::MessageBus::MessageBus

MessageBus for the messages flowing through the system. The admin has
visibility and control over the messages being published and consumed and can
restrict publishers and subscribers to only a subset of data available in the
system by defining authorization policies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the form
projects/{project}/locations/{location}/messageBuses/{message_bus}

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server assigned unique identifier for the channel. The value
is a UUID4 string and guaranteed to remain unchanged until the resource is
deleted.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. This checksum is computed by the server based on the value of
other fields, and might be sent only on update and delete requests to
ensure that the client has an up-to-date value before proceeding.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::MessageBus::MessageBus::LabelsEntry>)

Optional. Resource labels.

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::MessageBus::MessageBus::AnnotationsEntry>)

Optional. Resource annotations.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. Resource display name.

=item * C<< $msg->crypto_key_name() >> / C<< $msg->crypto_key_name($value) >>

Type: C<String>

Optional. Resource name of a KMS crypto key (managed by the user) used to
encrypt/decrypt their event data.

It must match the pattern
`projects/*/locations/*/keyRings/*/cryptoKeys/*`.

=item * C<< $msg->logging_config() >> / C<< $msg->logging_config($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::LoggingConfig::LoggingConfig>)

Optional. Config to control Platform logging for the Message Bus. This log
configuration is applied to the Message Bus itself, and all the Enrollments
attached to it.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::MessageBus::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
