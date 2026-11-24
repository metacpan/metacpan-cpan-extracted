package Google::Cloud::Notebooks::V2::Event;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiVnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YyL2V2ZW50LnByb3RvEhlnb29nbGUuY2xvdWQu
bm90ZWJvb2tzLnYyGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh9nb29nbGUv
cHJvdG9idWYvdGltZXN0YW1wLnByb3RvIowDCgVFdmVudBJACgtyZXBvcnRfdGltZRgBIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAVIKcmVwb3J0VGltZRJDCgR0eXBl
GAIgASgOMiouZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52Mi5FdmVudC5FdmVudFR5cGVCA+BB
AVIEdHlwZRJMCgdkZXRhaWxzGAMgAygLMi0uZ29vZ2xlLmNsb3VkLm5vdGVib29rcy52Mi5F
dmVudC5EZXRhaWxzRW50cnlCA+BBAVIHZGV0YWlscxo6CgxEZXRhaWxzRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJyCglFdmVudFR5cGUSGgoW
RVZFTlRfVFlQRV9VTlNQRUNJRklFRBAAEggKBElETEUQARINCglIRUFSVEJFQVQQAhIKCgZI
RUFMVEgQAxIPCgtNQUlOVEVOQU5DRRAEEhMKD01FVEFEQVRBX0NIQU5HRRAFQsEBCh1jb20u
Z29vZ2xlLmNsb3VkLm5vdGVib29rcy52MkIKRXZlbnRQcm90b1ABWjtjbG91ZC5nb29nbGUu
Y29tL2dvL25vdGVib29rcy9hcGl2Mi9ub3RlYm9va3NwYjtub3RlYm9va3NwYqoCGUdvb2ds
ZS5DbG91ZC5Ob3RlYm9va3MuVjLKAhlHb29nbGVcQ2xvdWRcTm90ZWJvb2tzXFYy6gIcR29v
Z2xlOjpDbG91ZDo6Tm90ZWJvb2tzOjpWMkquEQoGEgQOAEUBCrwECgEMEgMOABIysQQgQ29w
eXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGlj
ZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRo
aXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1h
eSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBh
Y2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBs
aWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1
dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFT
SVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0
aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNp
ZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVu
ZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEI
EgMVADYKCQoCCCUSAxUANgoICgEIEgMWAFIKCQoCCAsSAxYAUgoICgEIEgMXACIKCQoCCAoS
AxcAIgoICgEIEgMYACsKCQoCCAgSAxgAKwoICgEIEgMZADYKCQoCCAESAxkANgoICgEIEgMa
ADYKCQoCCCkSAxoANgoICgEIEgMbADUKCQoCCC0SAxsANQpYCgIEABIEHgBFARpMIFRoZSBk
ZWZpbml0aW9uIG9mIGFuIEV2ZW50IGZvciBhIG1hbmFnZWQgLyBzZW1pLW1hbmFnZWQgbm90
ZWJvb2sgaW5zdGFuY2UuCgoKCgMEAAESAx4IDQoyCgQEAAQAEgQgAjoDGiQgVGhlIGRlZmlu
aXRpb24gb2YgdGhlIGV2ZW50IHR5cGVzLgoKDAoFBAAEAAESAyAHEAooCgYEAAQAAgASAyIE
HxoZIEV2ZW50IGlzIG5vdCBzcGVjaWZpZWQuCgoOCgcEAAQAAgABEgMiBBoKDgoHBAAEAAIA
AhIDIh0eCi8KBgQABAACARIDJQQNGiAgVGhlIGluc3RhbmNlIC8gcnVudGltZSBpcyBpZGxl
CgoOCgcEAAQAAgEBEgMlBAgKDgoHBAAEAAIBAhIDJQsMCocBCgYEAAQAAgISAyoEEhp4IFRo
ZSBpbnN0YW5jZSAvIHJ1bnRpbWUgaXMgYXZhaWxhYmxlLgogVGhpcyBldmVudCBpbmRpY2F0
ZXMgdGhhdCBpbnN0YW5jZSAvIHJ1bnRpbWUgdW5kZXJseWluZyBjb21wdXRlIGlzCiBvcGVy
YXRpb25hbC4KCg4KBwQABAACAgESAyoEDQoOCgcEAAQAAgICEgMqEBEKfgoGBAAEAAIDEgMu
BA8abyBUaGUgaW5zdGFuY2UgLyBydW50aW1lIGhlYWx0aCBpcyBhdmFpbGFibGUuCiBUaGlz
IGV2ZW50IGluZGljYXRlcyB0aGF0IGluc3RhbmNlIC8gcnVudGltZSBoZWFsdGggaW5mb3Jt
YXRpb24uCgoOCgcEAAQAAgMBEgMuBAoKDgoHBAAEAAIDAhIDLg0OCtUBCgYEAAQAAgQSAzQE
FBrFASBUaGUgaW5zdGFuY2UgLyBydW50aW1lIGlzIGF2YWlsYWJsZS4KIFRoaXMgZXZlbnQg
YWxsb3dzIGluc3RhbmNlIC8gcnVudGltZSB0byBzZW5kIEhvc3QgbWFpbnRlbmFuY2UKIGlu
Zm9ybWF0aW9uIHRvIENvbnRyb2wgUGxhbmUuCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20v
Y29tcHV0ZS9kb2NzL2dwdXMvZ3B1LWhvc3QtbWFpbnRlbmFuY2UKCg4KBwQABAACBAESAzQE
DwoOCgcEAAQAAgQCEgM0EhMKhgEKBgQABAACBRIDOQQYGncgVGhlIGluc3RhbmNlIC8gcnVu
dGltZSBpcyBhdmFpbGFibGUuCiBUaGlzIGV2ZW50IGluZGljYXRlcyB0aGF0IHRoZSBpbnN0
YW5jZSBoYWQgbWV0YWRhdGEgdGhhdCBuZWVkcyB0byBiZQogbW9kaWZpZWQuCgoOCgcEAAQA
AgUBEgM5BBMKDgoHBAAEAAIFAhIDORYXCiwKBAQAAgASBD0CPi8aHiBPcHRpb25hbC4gRXZl
bnQgcmVwb3J0IHRpbWUuCgoMCgUEAAIABhIDPQIbCgwKBQQAAgABEgM9HCcKDAoFBAACAAMS
Az0qKwoMCgUEAAIACBIDPgYuCg8KCAQAAgAInAgAEgM+By0KJAoEBAACARIDQQI+GhcgT3B0
aW9uYWwuIEV2ZW50IHR5cGUuCgoMCgUEAAIBBhIDQQILCgwKBQQAAgEBEgNBDBAKDAoFBAAC
AQMSA0ETFAoMCgUEAAIBCBIDQRU9Cg8KCAQAAgEInAgAEgNBFjwKVQoEBAACAhIDRAJLGkgg
T3B0aW9uYWwuIEV2ZW50IGRldGFpbHMuIFRoaXMgZmllbGQgaXMgdXNlZCB0byBwYXNzIGV2
ZW50IGluZm9ybWF0aW9uLgoKDAoFBAACAgYSA0QCFQoMCgUEAAICARIDRBYdCgwKBQQAAgID
EgNEICEKDAoFBAACAggSA0QiSgoPCggEAAICCJwIABIDRCNJYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V2::Event::Event ===
    # Fields for Event
    # Field: report_time Type: 11 (.google.protobuf.Timestamp)
    # Field: type Type: 14 (.google.cloud.notebooks.v2.Event.EventType)
    # Field: details Type: 11 (.google.cloud.notebooks.v2.Event.DetailsEntry)

# Enum: Event::EventType
our $Event_EVENT_TYPE_UNSPECIFIED = 0;
our $Event_IDLE = 1;
our $Event_HEARTBEAT = 2;
our $Event_HEALTH = 3;
our $Event_MAINTENANCE = 4;
our $Event_METADATA_CHANGE = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V2::Event - Compiled Protocol Buffers messages for google/cloud/notebooks/v2/event.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V2::Event;

    my $msg = Google::Cloud::Notebooks::V2::Event::Event->new({
        report_time => $report_time,
        type => $type,
        details => $details,
    });

    # Read or update a field
    my $val = $msg->report_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V2::Event::Event->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v2/event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V2::Event::Event

The definition of an Event for a managed / semi-managed notebook instance.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->report_time() >> / C<< $msg->report_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. Event report time.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V2::Event::EventType>)

Optional. Event type.

=item * C<< $msg->details() >> / C<< $msg->details($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V2::Event::Event::DetailsEntry>)

Optional. Event details. This field is used to pass event information.

=back

=head3 Enum: Event::EventType

=over 4

=item * C<EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<IDLE> => C<1>

=item * C<HEARTBEAT> => C<2>

=item * C<HEALTH> => C<3>

=item * C<MAINTENANCE> => C<4>

=item * C<METADATA_CHANGE> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V2::Event::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
