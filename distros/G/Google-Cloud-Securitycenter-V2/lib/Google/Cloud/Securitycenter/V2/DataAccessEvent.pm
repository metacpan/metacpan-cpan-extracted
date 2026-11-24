package Google::Cloud::Securitycenter::V2::DataAccessEvent;

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
CjZnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjIvZGF0YV9hY2Nlc3NfZXZlbnQucHJv
dG8SHmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MhofZ29vZ2xlL3Byb3RvYnVmL3Rp
bWVzdGFtcC5wcm90byKvAgoPRGF0YUFjY2Vzc0V2ZW50EhkKCGV2ZW50X2lkGAEgASgJUgdl
dmVudElkEicKD3ByaW5jaXBhbF9lbWFpbBgCIAEoCVIOcHJpbmNpcGFsRW1haWwSVwoJb3Bl
cmF0aW9uGAMgASgOMjkuZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYyLkRhdGFBY2Nl
c3NFdmVudC5PcGVyYXRpb25SCW9wZXJhdGlvbhI5CgpldmVudF90aW1lGAQgASgLMhouZ29v
Z2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJZXZlbnRUaW1lIkQKCU9wZXJhdGlvbhIZChVPUEVS
QVRJT05fVU5TUEVDSUZJRUQQABIICgRSRUFEEAESCAoETU9WRRACEggKBENPUFkQA0LuAQoi
Y29tLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNlbnRlci52MkIURGF0YUFjY2Vzc0V2ZW50UHJv
dG9QAVpKY2xvdWQuZ29vZ2xlLmNvbS9nby9zZWN1cml0eWNlbnRlci9hcGl2Mi9zZWN1cml0
eWNlbnRlcnBiO3NlY3VyaXR5Y2VudGVycGKqAh5Hb29nbGUuQ2xvdWQuU2VjdXJpdHlDZW50
ZXIuVjLKAh5Hb29nbGVcQ2xvdWRcU2VjdXJpdHlDZW50ZXJcVjLqAiFHb29nbGU6OkNsb3Vk
OjpTZWN1cml0eUNlbnRlcjo6VjJK9w0KBhIEDgA6AQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAJwoJCgIDABIDEgApCggKAQgSAxQAOwoJCgIIJRIDFAA7
CggKAQgSAxUAYQoJCgIICxIDFQBhCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANQoJ
CgIICBIDFwA1CggKAQgSAxgAOwoJCgIIARIDGAA7CggKAQgSAxkAOwoJCgIIKRIDGQA7CggK
AQgSAxoAOgoJCgIILRIDGgA6CnwKAgQAEgQeADoBGnAgRGV0YWlscyBhYm91dCBhIGRhdGEg
YWNjZXNzIGF0dGVtcHQgbWFkZSBieSBhIHByaW5jaXBhbCBub3QgYXV0aG9yaXplZCB1bmRl
cgogYXBwbGljYWJsZSBkYXRhIHNlY3VyaXR5IHBvbGljeS4KCgoKAwQAARIDHggXCjUKBAQA
BAASBCACLAMaJyBUaGUgb3BlcmF0aW9uIG9mIGEgZGF0YSBhY2Nlc3MgZXZlbnQuCgoMCgUE
AAQAARIDIAcQCi4KBgQABAACABIDIgQeGh8gVGhlIG9wZXJhdGlvbiBpcyB1bnNwZWNpZmll
ZC4KCg4KBwQABAACAAESAyIEGQoOCgcEAAQAAgACEgMiHB0KLQoGBAAEAAIBEgMlBA0aHiBS
ZXByZXNlbnRzIGEgcmVhZCBvcGVyYXRpb24uCgoOCgcEAAQAAgEBEgMlBAgKDgoHBAAEAAIB
AhIDJQsMCi0KBgQABAACAhIDKAQNGh4gUmVwcmVzZW50cyBhIG1vdmUgb3BlcmF0aW9uLgoK
DgoHBAAEAAICARIDKAQICg4KBwQABAACAgISAygLDAotCgYEAAQAAgMSAysEDRoeIFJlcHJl
c2VudHMgYSBjb3B5IG9wZXJhdGlvbi4KCg4KBwQABAACAwESAysECAoOCgcEAAQAAgMCEgMr
CwwKNwoEBAACABIDLwIWGiogVW5pcXVlIGlkZW50aWZpZXIgZm9yIGRhdGEgYWNjZXNzIGV2
ZW50LgoKDAoFBAACAAUSAy8CCAoMCgUEAAIAARIDLwkRCgwKBQQAAgADEgMvFBUKmwEKBAQA
AgESAzMCHRqNASBUaGUgZW1haWwgYWRkcmVzcyBvZiB0aGUgcHJpbmNpcGFsIHRoYXQgYWNj
ZXNzZWQgdGhlIGRhdGEuIFRoZSBwcmluY2lwYWwKIGNvdWxkIGJlIGEgdXNlciBhY2NvdW50
LCBzZXJ2aWNlIGFjY291bnQsIEdvb2dsZSBncm91cCwgb3Igb3RoZXIuCgoMCgUEAAIBBRID
MwIICgwKBQQAAgEBEgMzCRgKDAoFBAACAQMSAzMbHApLCgQEAAICEgM2AhoaPiBUaGUgb3Bl
cmF0aW9uIHBlcmZvcm1lZCBieSB0aGUgcHJpbmNpcGFsIHRvIGFjY2VzcyB0aGUgZGF0YS4K
CgwKBQQAAgIGEgM2AgsKDAoFBAACAgESAzYMFQoMCgUEAAICAxIDNhgZCi4KBAQAAgMSAzkC
KxohIFRpbWVzdGFtcCBvZiBkYXRhIGFjY2VzcyBldmVudC4KCgwKBQQAAgMGEgM5AhsKDAoF
BAACAwESAzkcJgoMCgUEAAIDAxIDOSkqYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V2::DataAccessEvent::DataAccessEvent ===
    # Fields for DataAccessEvent
    # Field: event_id Type: 9 ()
    # Field: principal_email Type: 9 ()
    # Field: operation Type: 14 (.google.cloud.securitycenter.v2.DataAccessEvent.Operation)
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)

# Enum: DataAccessEvent::Operation
our $DataAccessEvent_OPERATION_UNSPECIFIED = 0;
our $DataAccessEvent_READ = 1;
our $DataAccessEvent_MOVE = 2;
our $DataAccessEvent_COPY = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V2::DataAccessEvent - Compiled Protocol Buffers messages for google/cloud/securitycenter/v2/data_access_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V2::DataAccessEvent;

    my $msg = Google::Cloud::Securitycenter::V2::DataAccessEvent::DataAccessEvent->new({
        event_id => $event_id,
        principal_email => $principal_email,
        operation => $operation,
        event_time => $event_time,
    });

    # Read or update a field
    my $val = $msg->event_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V2::DataAccessEvent::DataAccessEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v2/data_access_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V2::DataAccessEvent::DataAccessEvent

Details about a data access attempt made by a principal not authorized under
applicable data security policy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_id() >> / C<< $msg->event_id($value) >>

Type: C<String>

Unique identifier for data access event.

=item * C<< $msg->principal_email() >> / C<< $msg->principal_email($value) >>

Type: C<String>

The email address of the principal that accessed the data. The principal
could be a user account, service account, Google group, or other.

=item * C<< $msg->operation() >> / C<< $msg->operation($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V2::DataAccessEvent::Operation>)

The operation performed by the principal to access the data.

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp of data access event.

=back

=head3 Enum: DataAccessEvent::Operation

=over 4

=item * C<OPERATION_UNSPECIFIED> => C<0>

=item * C<READ> => C<1>

=item * C<MOVE> => C<2>

=item * C<COPY> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V2::DataAccessEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
