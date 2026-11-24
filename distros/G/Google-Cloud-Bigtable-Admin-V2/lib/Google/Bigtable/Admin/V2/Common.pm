package Google::Bigtable::Admin::V2::Common;

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
CiVnb29nbGUvYmlndGFibGUvYWRtaW4vdjIvY29tbW9uLnByb3RvEhhnb29nbGUuYmlndGFi
bGUuYWRtaW4udjIaH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8isAEKEU9wZXJh
dGlvblByb2dyZXNzEikKEHByb2dyZXNzX3BlcmNlbnQYASABKAVSD3Byb2dyZXNzUGVyY2Vu
dBI5CgpzdGFydF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3Rh
cnRUaW1lEjUKCGVuZF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIH
ZW5kVGltZSo9CgtTdG9yYWdlVHlwZRIcChhTVE9SQUdFX1RZUEVfVU5TUEVDSUZJRUQQABIH
CgNTU0QQARIHCgNIREQQAkLOAQocY29tLmdvb2dsZS5iaWd0YWJsZS5hZG1pbi52MkILQ29t
bW9uUHJvdG9QAVo4Y2xvdWQuZ29vZ2xlLmNvbS9nby9iaWd0YWJsZS9hZG1pbi9hcGl2Mi9h
ZG1pbnBiO2FkbWlucGKqAh5Hb29nbGUuQ2xvdWQuQmlndGFibGUuQWRtaW4uVjLKAh5Hb29n
bGVcQ2xvdWRcQmlndGFibGVcQWRtaW5cVjLqAiJHb29nbGU6OkNsb3VkOjpCaWd0YWJsZTo6
QWRtaW46OlYySpgMCgYSBA4ANQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
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
CgoICgECEgMQACEKCQoCAwASAxIAKQoICgEIEgMUADsKCQoCCCUSAxQAOwoICgEIEgMVAE8K
CQoCCAsSAxUATwoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXACwKCQoCCAgSAxcALAoI
CgEIEgMYADUKCQoCCAESAxgANQoICgEIEgMZADwKCQoCCCkSAxkAPAoICgEIEgMaADsKCQoC
CC0SAxoAOwo/CgIFABIEHQAmARozIFN0b3JhZ2UgbWVkaWEgdHlwZXMgZm9yIHBlcnNpc3Rp
bmcgQmlndGFibGUgZGF0YS4KCgoKAwUAARIDHQUQCjcKBAUAAgASAx8CHxoqIFRoZSB1c2Vy
IGRpZCBub3Qgc3BlY2lmeSBhIHN0b3JhZ2UgdHlwZS4KCgwKBQUAAgABEgMfAhoKDAoFBQAC
AAISAx8dHgoyCgQFAAIBEgMiAgoaJSBGbGFzaCAoU1NEKSBzdG9yYWdlIHNob3VsZCBiZSB1
c2VkLgoKDAoFBQACAQESAyICBQoMCgUFAAIBAhIDIggJCjsKBAUAAgISAyUCChouIE1hZ25l
dGljIGRyaXZlIChIREQpIHN0b3JhZ2Ugc2hvdWxkIGJlIHVzZWQuCgoMCgUFAAICARIDJQIF
CgwKBQUAAgICEgMlCAkKZQoCBAASBCoANQEaWSBFbmNhcHN1bGF0ZXMgcHJvZ3Jlc3MgcmVs
YXRlZCBpbmZvcm1hdGlvbiBmb3IgYSBDbG91ZCBCaWd0YWJsZSBsb25nCiBydW5uaW5nIG9w
ZXJhdGlvbi4KCgoKAwQAARIDKggZClwKBAQAAgASAy0CHRpPIFBlcmNlbnQgY29tcGxldGlv
biBvZiB0aGUgb3BlcmF0aW9uLgogVmFsdWVzIGFyZSBiZXR3ZWVuIDAgYW5kIDEwMCBpbmNs
dXNpdmUuCgoMCgUEAAIABRIDLQIHCgwKBQQAAgABEgMtCBgKDAoFBAACAAMSAy0bHAotCgQE
AAIBEgMwAisaICBUaW1lIHRoZSByZXF1ZXN0IHdhcyByZWNlaXZlZC4KCgwKBQQAAgEGEgMw
AhsKDAoFBAACAQESAzAcJgoMCgUEAAIBAxIDMCkqCl4KBAQAAgISAzQCKRpRIElmIHNldCwg
dGhlIHRpbWUgYXQgd2hpY2ggdGhpcyBvcGVyYXRpb24gZmFpbGVkIG9yIHdhcyBjb21wbGV0
ZWQKIHN1Y2Nlc3NmdWxseS4KCgwKBQQAAgIGEgM0AhsKDAoFBAACAgESAzQcJAoMCgUEAAIC
AxIDNCcoYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Bigtable::Admin::V2::Common::OperationProgress ===
    # Fields for OperationProgress
    # Field: progress_percent Type: 5 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Bigtable::Admin::V2::Common - Compiled Protocol Buffers messages for google/bigtable/admin/v2/common.proto

=head1 SYNOPSIS

    use Google::Bigtable::Admin::V2::Common;

    my $msg = Google::Bigtable::Admin::V2::Common::OperationProgress->new({
        progress_percent => $progress_percent,
        start_time => $start_time,
        end_time => $end_time,
    });

    # Read or update a field
    my $val = $msg->progress_percent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Bigtable::Admin::V2::Common::OperationProgress->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/bigtable/admin/v2/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Bigtable::Admin::V2::Common::OperationProgress

Encapsulates progress related information for a Cloud Bigtable long
running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->progress_percent() >> / C<< $msg->progress_percent($value) >>

Type: C<Int32>

Percent completion of the operation.
Values are between 0 and 100 inclusive.

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time the request was received.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

If set, the time at which this operation failed or was completed
successfully.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Bigtable::Admin::V2::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
