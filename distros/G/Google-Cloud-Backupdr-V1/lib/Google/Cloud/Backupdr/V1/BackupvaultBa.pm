package Google::Cloud::Backupdr::V1::BackupvaultBa;

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
Ci1nb29nbGUvY2xvdWQvYmFja3VwZHIvdjEvYmFja3VwdmF1bHRfYmEucHJvdG8SGGdvb2ds
ZS5jbG91ZC5iYWNrdXBkci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxof
Z29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byK3AwofQmFja3VwQXBwbGlhbmNlQmFj
a3VwUHJvcGVydGllcxItCg1nZW5lcmF0aW9uX2lkGAEgASgFQgPgQQNIAFIMZ2VuZXJhdGlv
bklkiAEBEkkKDWZpbmFsaXplX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNIAVIMZmluYWxpemVUaW1liAEBEl8KGXJlY292ZXJ5X3JhbmdlX3N0YXJ0X3Rp
bWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQFIAlIWcmVjb3ZlcnlS
YW5nZVN0YXJ0VGltZYgBARJbChdyZWNvdmVyeV9yYW5nZV9lbmRfdGltZRgEIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAUgDUhRyZWNvdmVyeVJhbmdlRW5kVGltZYgB
AUIQCg5fZ2VuZXJhdGlvbl9pZEIQCg5fZmluYWxpemVfdGltZUIcChpfcmVjb3ZlcnlfcmFu
Z2Vfc3RhcnRfdGltZUIaChhfcmVjb3ZlcnlfcmFuZ2VfZW5kX3RpbWVCwgEKHGNvbS5nb29n
bGUuY2xvdWQuYmFja3VwZHIudjFCEkJhY2t1cHZhdWx0QmFQcm90b1ABWjhjbG91ZC5nb29n
bGUuY29tL2dvL2JhY2t1cGRyL2FwaXYxL2JhY2t1cGRycGI7YmFja3VwZHJwYqoCGEdvb2ds
ZS5DbG91ZC5CYWNrdXBEUi5WMcoCGEdvb2dsZVxDbG91ZFxCYWNrdXBEUlxWMeoCG0dvb2ds
ZTo6Q2xvdWQ6OkJhY2t1cERSOjpWMUq/DAoGEgQOADABCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMV
ADUKCQoCCCUSAxUANQoICgEIEgMWAE8KCQoCCAsSAxYATwoICgEIEgMXACIKCQoCCAoSAxcA
IgoICgEIEgMYADMKCQoCCAgSAxgAMwoICgEIEgMZADUKCQoCCAESAxkANQoICgEIEgMaADUK
CQoCCCkSAxoANQoICgEIEgMbADQKCQoCCC0SAxsANAphCgIEABIEHwAwARpVIEJhY2t1cEFw
cGxpYW5jZUJhY2t1cFByb3BlcnRpZXMgcmVwcmVzZW50cyBCYWNrdXBEUiBiYWNrdXAgYXBw
bGlhbmNlJ3MKIHByb3BlcnRpZXMuCgoKCgMEAAESAx8IJwpgCgQEAAIAEgMiAk8aUyBPdXRw
dXQgb25seS4gVGhlIG51bWVyaWMgZ2VuZXJhdGlvbiBJRCBvZiB0aGUgYmFja3VwIChtb25v
dG9uaWNhbGx5CiBpbmNyZWFzaW5nKS4KCgwKBQQAAgAEEgMiAgoKDAoFBAACAAUSAyILEAoM
CgUEAAIAARIDIhEeCgwKBQQAAgADEgMiISIKDAoFBAACAAgSAyIjTgoPCggEAAIACJwIABID
IiRNCnAKBAQAAgESBCYCJzIaYiBPdXRwdXQgb25seS4gVGhlIHRpbWUgd2hlbiB0aGlzIGJh
Y2t1cCBvYmplY3Qgd2FzIGZpbmFsaXplZCAoaWYgbm9uZSwKIGJhY2t1cCBpcyBub3QgZmlu
YWxpemVkKS4KCgwKBQQAAgEEEgMmAgoKDAoFBAACAQYSAyYLJAoMCgUEAAIBARIDJiUyCgwK
BQQAAgEDEgMmNTYKDAoFBAACAQgSAycGMQoPCggEAAIBCJwIABIDJwcwClIKBAQAAgISBCoC
Ky8aRCBPcHRpb25hbC4gVGhlIGVhcmxpZXN0IHRpbWVzdGFtcCBvZiBkYXRhIGF2YWlsYWJs
ZSBpbiB0aGlzIEJhY2t1cC4KCgwKBQQAAgIEEgMqAgoKDAoFBAACAgYSAyoLJAoMCgUEAAIC
ARIDKiU+CgwKBQQAAgIDEgMqQUIKDAoFBAACAggSAysGLgoPCggEAAICCJwIABIDKwctClAK
BAQAAgMSBC4CLy8aQiBPcHRpb25hbC4gVGhlIGxhdGVzdCB0aW1lc3RhbXAgb2YgZGF0YSBh
dmFpbGFibGUgaW4gdGhpcyBCYWNrdXAuCgoMCgUEAAIDBBIDLgIKCgwKBQQAAgMGEgMuCyQK
DAoFBAACAwESAy4lPAoMCgUEAAIDAxIDLj9ACgwKBQQAAgMIEgMvBi4KDwoIBAACAwicCAAS
Ay8HLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1::BackupvaultBa::BackupApplianceBackupProperties ===
    # Fields for BackupApplianceBackupProperties
    # Field: generation_id Type: 5 ()
    # Field: finalize_time Type: 11 (.google.protobuf.Timestamp)
    # Field: recovery_range_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: recovery_range_end_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1::BackupvaultBa - Compiled Protocol Buffers messages for google/cloud/backupdr/v1/backupvault_ba.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1::BackupvaultBa;

    my $msg = Google::Cloud::Backupdr::V1::BackupvaultBa::BackupApplianceBackupProperties->new({
        generation_id => $generation_id,
        finalize_time => $finalize_time,
        recovery_range_start_time => $recovery_range_start_time,
        recovery_range_end_time => $recovery_range_end_time,
    });

    # Read or update a field
    my $val = $msg->generation_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1::BackupvaultBa::BackupApplianceBackupProperties->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1/backupvault_ba.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1::BackupvaultBa::BackupApplianceBackupProperties

BackupApplianceBackupProperties represents BackupDR backup appliance's
properties.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->generation_id() >> / C<< $msg->generation_id($value) >>

Type: C<Int32>

Output only. The numeric generation ID of the backup (monotonically
increasing).

=item * C<< $msg->finalize_time() >> / C<< $msg->finalize_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when this backup object was finalized (if none,
backup is not finalized).

=item * C<< $msg->recovery_range_start_time() >> / C<< $msg->recovery_range_start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The earliest timestamp of data available in this Backup.

=item * C<< $msg->recovery_range_end_time() >> / C<< $msg->recovery_range_end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The latest timestamp of data available in this Backup.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1::BackupvaultBa::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
