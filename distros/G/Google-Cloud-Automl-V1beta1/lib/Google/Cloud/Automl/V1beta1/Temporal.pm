package Google::Cloud::Automl::V1beta1::Temporal;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGVtcG9yYWwucHJvdG8SG2dvb2dsZS5j
bG91ZC5hdXRvbWwudjFiZXRhMRoeZ29vZ2xlL3Byb3RvYnVmL2R1cmF0aW9uLnByb3RvIpcB
CgtUaW1lU2VnbWVudBJFChFzdGFydF90aW1lX29mZnNldBgBIAEoCzIZLmdvb2dsZS5wcm90
b2J1Zi5EdXJhdGlvblIPc3RhcnRUaW1lT2Zmc2V0EkEKD2VuZF90aW1lX29mZnNldBgCIAEo
CzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblINZW5kVGltZU9mZnNldEKbAQofY29tLmdv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMVABWjdjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9t
bC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1dG9NbFxW
MWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExStcICgYSBA4AIwEKvAQK
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
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAKAoI
CgEIEgMUAE4KCQoCCAsSAxQATgoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWADgKCQoC
CAESAxYAOAoICgEIEgMXADgKCQoCCCkSAxcAOAoICgEIEgMYADcKCQoCCC0SAxgANwpYCgIE
ABIEGwAjARpMIEEgdGltZSBwZXJpb2QgaW5zaWRlIG9mIGFuIGV4YW1wbGUgdGhhdCBoYXMg
YSB0aW1lIGRpbWVuc2lvbiAoZS5nLiB2aWRlbykuCgoKCgMEAAESAxsIEwprCgQEAAIAEgMe
AjEaXiBTdGFydCBvZiB0aGUgdGltZSBzZWdtZW50IChpbmNsdXNpdmUpLCByZXByZXNlbnRl
ZCBhcyB0aGUgZHVyYXRpb24gc2luY2UKIHRoZSBleGFtcGxlIHN0YXJ0LgoKDAoFBAACAAYS
Ax4CGgoMCgUEAAIAARIDHhssCgwKBQQAAgADEgMeLzAKaQoEBAACARIDIgIvGlwgRW5kIG9m
IHRoZSB0aW1lIHNlZ21lbnQgKGV4Y2x1c2l2ZSksIHJlcHJlc2VudGVkIGFzIHRoZSBkdXJh
dGlvbiBzaW5jZSB0aGUKIGV4YW1wbGUgc3RhcnQuCgoMCgUEAAIBBhIDIgIaCgwKBQQAAgEB
EgMiGyoKDAoFBAACAQMSAyItLmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Temporal::TimeSegment ===
    # Fields for TimeSegment
    # Field: start_time_offset Type: 11 (.google.protobuf.Duration)
    # Field: end_time_offset Type: 11 (.google.protobuf.Duration)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Temporal - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/temporal.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Temporal;

    my $msg = Google::Cloud::Automl::V1beta1::Temporal::TimeSegment->new({
        start_time_offset => $start_time_offset,
        end_time_offset => $end_time_offset,
    });

    # Read or update a field
    my $val = $msg->start_time_offset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Temporal::TimeSegment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/temporal.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Temporal::TimeSegment

A time period inside of an example that has a time dimension (e.g. video).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time_offset() >> / C<< $msg->start_time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Start of the time segment (inclusive), represented as the duration since
the example start.

=item * C<< $msg->end_time_offset() >> / C<< $msg->end_time_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

End of the time segment (exclusive), represented as the duration since the
example start.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Temporal::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
