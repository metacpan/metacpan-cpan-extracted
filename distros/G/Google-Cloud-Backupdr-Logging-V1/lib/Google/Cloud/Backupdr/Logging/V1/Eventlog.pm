package Google::Cloud::Backupdr::Logging::V1::Eventlog;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYmFja3VwZHIvbG9nZ2luZy92MS9ldmVudGxvZy5wcm90bxIgZ29v
Z2xlLmNsb3VkLmJhY2t1cGRyLmxvZ2dpbmcudjEikgIKBUV2ZW50Eh0KCmV2ZW50X3RpbWUY
ASABKAlSCWV2ZW50VGltZRIUCgVzcmNpZBgCIAEoA1IFc3JjaWQSIwoNZXJyb3JfbWVzc2Fn
ZRgDIAEoCVIMZXJyb3JNZXNzYWdlEhkKCGV2ZW50X2lkGAQgASgFUgdldmVudElkEhwKCWNv
bXBvbmVudBgFIAEoCVIJY29tcG9uZW50EiUKDmFwcGxpYW5jZV9uYW1lGAYgASgDUg1hcHBs
aWFuY2VOYW1lEhkKCGFwcF9uYW1lGAcgASgJUgdhcHBOYW1lEhkKCGFwcF90eXBlGAggASgJ
UgdhcHBUeXBlEhkKCGpvYl9uYW1lGAkgASgJUgdqb2JOYW1lQkBaPmNsb3VkLmdvb2dsZS5j
b20vZ28vYmFja3VwZHIvbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiSqoOCgYS
BA4ANQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACkKCAoB
CBIDEgBVCgkKAggLEgMSAFUKHgoCBAASBBUANQEaEiBUaGlzIGlzIGFuIGV2ZW50CgoKCgME
AAESAxUIDQpRCgQEAAIAEgMXAhgaRCBUaGUgZXZlbnRfdGltZSBmaWVsZCBkaXNwbGF5cyB0
aGUgdGltZSB3aGVuIHRoZSBldmVudCB3YXMgcmVwb3J0ZWQKCgwKBQQAAgAFEgMXAggKDAoF
BAACAAESAxcJEwoMCgUEAAIAAxIDFxYXCmAKBAQAAgESAxsCEhpTIFRoZSBzcmNpZCBmaWVs
ZCBkaXNwbGF5cyB1bmlxdWUgaWQgb2YgdGhlIGV2ZW50IG9jY3VycmVkIGluIHRoZSBiYWNr
dXAKIGFwcGxpYW5jZQoKDAoFBAACAQUSAxsCBwoMCgUEAAIBARIDGwgNCgwKBQQAAgEDEgMb
EBEKXQoEBAACAhIDHwIbGlAgVGhlIGVycm9ybWVzc2FnZSBmaWVsZCBkZXNjcmliZXMgdGhl
IGRldGFpbGVkIGVycm9yIGFzc29jaWF0ZWQgd2l0aCB0aGUKIGV2ZW50CgoMCgUEAAICBRID
HwIICgwKBQQAAgIBEgMfCRYKDAoFBAACAgMSAx8ZGgpOCgQEAAIDEgMiAhUaQSBUaGUgZXZl
bnRfaWQgZmllbGQgZGlzcGxheXMgdW5pcXVlIGlkIGFzc29jaWF0ZWQgd2l0aCB0aGUgZXJy
b3IKCgwKBQQAAgMFEgMiAgcKDAoFBAACAwESAyIIEAoMCgUEAAIDAxIDIhMUCkMKBAQAAgQS
AyUCFxo2IFRoZSBjb21wb25lbnQgZmllbGQgZGlzcGxheXMgdGhlIHNvdXJjZSBvZiB0aGUg
ZXZlbnQKCgwKBQQAAgQFEgMlAggKDAoFBAACBAESAyUJEgoMCgUEAAIEAxIDJRUWCmIKBAQA
AgUSAykCGxpVIFRoZSBhcHBsaWFuY2VfaWQgZmllbGQgZGlzcGxheXMgdW5pcXVlIGlkIG9m
IHRoZSBhcHBsaWFuY2Ugb24gd2hpY2ggZXZlbnQKIG9jY3VycmVkCgoMCgUEAAIFBRIDKQIH
CgwKBQQAAgUBEgMpCBYKDAoFBAACBQMSAykZGgpcCgQEAAIGEgMtAhYaTyBUaGUgYXBwbmFt
ZSBmaWVsZCBkaXNwbGF5cyBuYW1lIG9mIHRoZSBhcHBsaWNhdGlvbiBhc3NvY2lhdGVkIHdp
dGggdGhlCiBldmVudAoKDAoFBAACBgUSAy0CCAoMCgUEAAIGARIDLQkRCgwKBQQAAgYDEgMt
FBUKXAoEBAACBxIDMQIWGk8gVGhlIGFwcHR5cGUgZmllbGQgZGlzcGxheXMgdHlwZSBvZiB0
aGUgYXBwbGljYXRpb24gYXNzb2NpYXRlZCB3aXRoIHRoZQogZXZlbnQKCgwKBQQAAgcFEgMx
AggKDAoFBAACBwESAzEJEQoMCgUEAAIHAxIDMRQVClMKBAQAAggSAzQCFhpGIFRoZSBqb2Ju
YW1lIGZpZWxkIGRpc3BsYXlzIG5hbWUgb2YgdGhlIGpvYiBhc3NvY2lhdGVkIHdpdGggdGhl
IGV2ZW50CgoMCgUEAAIIBRIDNAIICgwKBQQAAggBEgM0CREKDAoFBAACCAMSAzQUFWIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::Logging::V1::Eventlog::Event ===
    # Fields for Event
    # Field: event_time Type: 9 ()
    # Field: srcid Type: 3 ()
    # Field: error_message Type: 9 ()
    # Field: event_id Type: 5 ()
    # Field: component Type: 9 ()
    # Field: appliance_name Type: 3 ()
    # Field: app_name Type: 9 ()
    # Field: app_type Type: 9 ()
    # Field: job_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::Logging::V1::Eventlog - Compiled Protocol Buffers messages for google/cloud/backupdr/logging/v1/eventlog.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::Logging::V1::Eventlog;

    my $msg = Google::Cloud::Backupdr::Logging::V1::Eventlog::Event->new({
        event_time => $event_time,
        srcid => $srcid,
        error_message => $error_message,
        event_id => $event_id,
    });

    # Read or update a field
    my $val = $msg->event_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::Logging::V1::Eventlog::Event->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/logging/v1/eventlog.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::Logging::V1::Eventlog::Event

This is an event

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<String>

The event_time field displays the time when the event was reported

=item * C<< $msg->srcid() >> / C<< $msg->srcid($value) >>

Type: C<Int64>

The srcid field displays unique id of the event occurred in the backup
appliance

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

The errormessage field describes the detailed error associated with the
event

=item * C<< $msg->event_id() >> / C<< $msg->event_id($value) >>

Type: C<Int32>

The event_id field displays unique id associated with the error

=item * C<< $msg->component() >> / C<< $msg->component($value) >>

Type: C<String>

The component field displays the source of the event

=item * C<< $msg->appliance_name() >> / C<< $msg->appliance_name($value) >>

Type: C<Int64>

The appliance_id field displays unique id of the appliance on which event
occurred

=item * C<< $msg->app_name() >> / C<< $msg->app_name($value) >>

Type: C<String>

The appname field displays name of the application associated with the
event

=item * C<< $msg->app_type() >> / C<< $msg->app_type($value) >>

Type: C<String>

The apptype field displays type of the application associated with the
event

=item * C<< $msg->job_name() >> / C<< $msg->job_name($value) >>

Type: C<String>

The jobname field displays name of the job associated with the event

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::Logging::V1::Eventlog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
