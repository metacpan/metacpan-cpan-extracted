package Google::Cloud::Chronicle::V1::Event;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Backstory::Udm };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvY2hyb25pY2xlL3YxL2V2ZW50LnByb3RvEhlnb29nbGUuY2xvdWQu
Y2hyb25pY2xlLnYxGhNiYWNrc3RvcnkvdWRtLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvIrYBCgVFdmVudBISCgRuYW1lGAEgASgJUgRuYW1lEicKA3VkbRgCIAEoCzIVLmdv
b2dsZS5iYWNrc3RvcnkuVURNUgN1ZG06cOpBbQoeY2hyb25pY2xlLmdvb2dsZWFwaXMuY29t
L0V2ZW50Ektwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vaW5zdGFu
Y2VzL3tpbnN0YW5jZX0vZXZlbnRzL3tldmVudH1CwQEKHWNvbS5nb29nbGUuY2xvdWQuY2hy
b25pY2xlLnYxQgpFdmVudFByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vY2hyb25pY2xl
L2FwaXYxL2Nocm9uaWNsZXBiO2Nocm9uaWNsZXBiqgIZR29vZ2xlLkNsb3VkLkNocm9uaWNs
ZS5WMcoCGUdvb2dsZVxDbG91ZFxDaHJvbmljbGVcVjHqAhxHb29nbGU6OkNsb3VkOjpDaHJv
bmljbGU6OlYxSuoJCgYSBA4ALQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACIKCQoCAwASAxIAHQoJCgIDARIDEwAjCggKAQgSAxUANgoJCgIIJRIDFQA2
CggKAQgSAxYAUgoJCgIICxIDFgBSCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAKwoJ
CgIICBIDGAArCggKAQgSAxkANgoJCgIIARIDGQA2CggKAQgSAxoANgoJCgIIKRIDGgA2CggK
AQgSAxsANQoJCgIILRIDGwA1ClQKAgQAEgQeAC0BGkggRXZlbnQgaXMgYSByZXNvdXJjZSB0
aGF0IGNvbnRhaW5zIGluZm9ybWF0aW9uIGFib3V0IGEgdGVsZW1ldHJ5IGV2ZW50LgoKCgoD
BAABEgMeCA0KCwoDBAAHEgQfAiIECg0KBQQAB50IEgQfAiIECvEBCgQEAAIAEgMpAhIa4wEg
VGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGV2ZW50LgogRm9ybWF0OgogcHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2luc3RhbmNlcy97aW5zdGFuY2V9L2V2ZW50
cy97ZXZlbnR9CiB3aGVyZSAnZXZlbnQnIGlzIFVSTC1lbmNvZGVkIEJhc2U2NC4gVGhlIHVu
ZW5jb2RlZCB2YWx1ZSBvZiAnZXZlbnQnIGNhbgogYWxzbyBiZSBmb3VuZCBpbiB1ZG0ubWV0
YWRhdGEuaWQuCgoMCgUEAAIABRIDKQIICgwKBQQAAgABEgMpCQ0KDAoFBAACAAMSAykQEQoo
CgQEAAIBEgMsAhgaGyBFdmVudCBkYXRhIGluIFVETSBmb3JtYXQuCgoMCgUEAAIBBhIDLAIP
CgwKBQQAAgEBEgMsEBMKDAoFBAACAQMSAywWF2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Chronicle::V1::Event::Event ===
    # Fields for Event
    # Field: name Type: 9 ()
    # Field: udm Type: 11 (.google.backstory.UDM)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Chronicle::V1::Event - Compiled Protocol Buffers messages for google/cloud/chronicle/v1/event.proto

=head1 SYNOPSIS

    use Google::Cloud::Chronicle::V1::Event;

    my $msg = Google::Cloud::Chronicle::V1::Event::Event->new({
        name => $name,
        udm => $udm,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Chronicle::V1::Event::Event->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/chronicle/v1/event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Chronicle::V1::Event::Event

Event is a resource that contains information about a telemetry event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The resource name of the event.
Format:
projects/{project}/locations/{location}/instances/{instance}/events/{event}
where 'event' is URL-encoded Base64. The unencoded value of 'event' can
also be found in udm.metadata.id.

=item * C<< $msg->udm() >> / C<< $msg->udm($value) >>

Type: C<Message> (L<Google::Backstory::Udm::UDM>)

Event data in UDM format.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Chronicle::V1::Event::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
