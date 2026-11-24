package Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog;

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
Cj1nb29nbGUvY2xvdWQvbWV0YXN0b3JlL2xvZ2dpbmcvdjEvc2NoZWR1bGVkX2JhY2t1cHNf
bG9nLnByb3RvEiFnb29nbGUuY2xvdWQubWV0YXN0b3JlLmxvZ2dpbmcudjEaH2dvb2dsZS9h
cGkvZmllbGRfYmVoYXZpb3IucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8i2gMKF1NjaGVkdWxlZEJhY2t1cExvZ0VudHJ5EhsKCWJhY2t1cF9pZBgBIAEoCVIIYmFj
a3VwSWQSGAoHc2VydmljZRgCIAEoCVIHc2VydmljZRI5CgpzdGFydF90aW1lGAMgASgLMhou
Z29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJc3RhcnRUaW1lEjUKCGVuZF90aW1lGAQgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIHZW5kVGltZRJbCgVzdGF0ZRgFIAEoDjJA
Lmdvb2dsZS5jbG91ZC5tZXRhc3RvcmUubG9nZ2luZy52MS5TY2hlZHVsZWRCYWNrdXBMb2dF
bnRyeS5TdGF0ZUID4EEDUgVzdGF0ZRIqChFiYWNrdXBfc2l6ZV9ieXRlcxgGIAEoA1IPYmFj
a3VwU2l6ZUJ5dGVzEicKD2JhY2t1cF9sb2NhdGlvbhgHIAEoCVIOYmFja3VwTG9jYXRpb24S
GAoHbWVzc2FnZRgIIAEoCVIHbWVzc2FnZSJKCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklF
RBAAEg8KC0lOX1BST0dSRVNTEAESDQoJU1VDQ0VFREVEEAISCgoGRkFJTEVEEANCgAEKIWdv
b2dsZS5jbG91ZC5tZXRhc3RvcmUubG9nZ2luZy52MUIYU2NoZWR1bGVkQmFja3Vwc0xvZ1By
b3RvUAFaP2Nsb3VkLmdvb2dsZS5jb20vZ28vbWV0YXN0b3JlL2xvZ2dpbmcvYXBpdjEvbG9n
Z2luZ3BiO2xvZ2dpbmdwYkrBEAoGEgQOAEQBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMVAFYKCQoC
CAsSAxUAVgoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADkKCQoCCAgSAxcAOQoICgEI
EgMYADoKCQoCCAESAxgAOgpDCgIEABIEGwBEARo3IENsb3VkIExvZ2dpbmcgbG9nIHNjaGVt
YSBmb3Igc2NoZWR1bGVkIGJhY2t1cCBldmVudHMuCgoKCgMEAAESAxsIHwowCgQEAAQAEgQd
AikDGiIgVGhlIGN1cnJlbnQgc3RhdGUgb2YgdGhlIGJhY2t1cC4KCgwKBQQABAABEgMdBwwK
NAoGBAAEAAIAEgMfBBoaJSBUaGUgc3RhdGUgb2YgdGhlIGJhY2t1cCBpcyB1bmtub3duLgoK
DgoHBAAEAAIAARIDHwQVCg4KBwQABAACAAISAx8YGQorCgYEAAQAAgESAyIEFBocIFRoZSBi
YWNrdXAgaXMgaW4gcHJvZ3Jlc3MuCgoOCgcEAAQAAgEBEgMiBA8KDgoHBAAEAAIBAhIDIhIT
CiYKBgQABAACAhIDJQQSGhcgVGhlIGJhY2t1cCBjb21wbGV0ZWQuCgoOCgcEAAQAAgIBEgMl
BA0KDgoHBAAEAAICAhIDJRARCiMKBgQABAACAxIDKAQPGhQgVGhlIGJhY2t1cCBmYWlsZWQu
CgoOCgcEAAQAAgMBEgMoBAoKDgoHBAAEAAIDAhIDKA0OCiQKBAQAAgASAywCFxoXIFRoZSBJ
RCBvZiB0aGUgYmFja3VwLgoKDAoFBAACAAUSAywCCAoMCgUEAAIAARIDLAkSCgwKBQQAAgAD
EgMsFRYKlwEKBAQAAgESAzACFRqJASBUaGUgcmVsYXRpdmUgcmVzb3VyY2UgbmFtZSBvZiBh
IE1ldGFzdG9yZSBzZXJ2aWNlIGluIHRoZSBmb3JtIG9mCiBgcHJvamVjdHMve3Byb2plY3Rf
aWR9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L3NlcnZpY2VzL3tzZXJ2aWNlX2lkfWAKCgwK
BQQAAgEFEgMwAggKDAoFBAACAQESAzAJEAoMCgUEAAIBAxIDMBMUCjUKBAQAAgISAzMCKxoo
IFRpbWVzdGFtcCB3aGVuIHRoZSBiYWNrdXAgd2FzIHN0YXJ0ZWQuCgoMCgUEAAICBhIDMwIb
CgwKBQQAAgIBEgMzHCYKDAoFBAACAgMSAzMpKgo3CgQEAAIDEgM2AikaKiBUaW1lc3RhbXAg
d2hlbiB0aGUgYmFja3VwIHdhcyBjb21wbGV0ZWQuCgoMCgUEAAIDBhIDNgIbCgwKBQQAAgMB
EgM2HCQKDAoFBAACAwMSAzYnKAo8CgQEAAIEEgM5Aj4aLyBPdXRwdXQgb25seS4gVGhlIGN1
cnJlbnQgc3RhdGUgb2YgdGhlIGJhY2t1cC4KCgwKBQQAAgQGEgM5AgcKDAoFBAACBAESAzkI
DQoMCgUEAAIEAxIDORARCgwKBQQAAgQIEgM5Ej0KDwoIBAACBAicCAASAzkTPAowCgQEAAIF
EgM8Ah4aIyBTaXplIG9mIHRoZSBiYWNrdXAgZGF0YSBpbiBieXRlcy4KCgwKBQQAAgUFEgM8
AgcKDAoFBAACBQESAzwIGQoMCgUEAAIFAxIDPBwdCmkKBAQAAgYSA0ACHRpcIEEgQ2xvdWQg
U3RvcmFnZSBVUkkgb2YgYSBmb2xkZXIsIGluIHRoZSBmb3JtYXQKIGBnczovLzxidWNrZXRf
bmFtZT4vPHBhdGhfaW5zaWRlX2J1Y2tldD5gLgoKDAoFBAACBgUSA0ACCAoMCgUEAAIGARID
QAkYCgwKBQQAAgYDEgNAGxwKSQoEBAACBxIDQwIVGjwgTWVzc2FnZSB0aGF0IHByb3ZpZGVz
IChvcHRpb25hbCkgZGV0YWlscyBhYm91dCB0aGUgYmFja3VwLgoKDAoFBAACBwUSA0MCCAoM
CgUEAAIHARIDQwkQCgwKBQQAAgcDEgNDExRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::ScheduledBackupLogEntry ===
    # Fields for ScheduledBackupLogEntry
    # Field: backup_id Type: 9 ()
    # Field: service Type: 9 ()
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.metastore.logging.v1.ScheduledBackupLogEntry.State)
    # Field: backup_size_bytes Type: 3 ()
    # Field: backup_location Type: 9 ()
    # Field: message Type: 9 ()

# Enum: ScheduledBackupLogEntry::State
our $ScheduledBackupLogEntry_STATE_UNSPECIFIED = 0;
our $ScheduledBackupLogEntry_IN_PROGRESS = 1;
our $ScheduledBackupLogEntry_SUCCEEDED = 2;
our $ScheduledBackupLogEntry_FAILED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog - Compiled Protocol Buffers messages for google/cloud/metastore/logging/v1/scheduled_backups_log.proto

=head1 SYNOPSIS

    use Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog;

    my $msg = Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::ScheduledBackupLogEntry->new({
        backup_id => $backup_id,
        service => $service,
        start_time => $start_time,
        end_time => $end_time,
    });

    # Read or update a field
    my $val = $msg->backup_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::ScheduledBackupLogEntry->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/metastore/logging/v1/scheduled_backups_log.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::ScheduledBackupLogEntry

Cloud Logging log schema for scheduled backup events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->backup_id() >> / C<< $msg->backup_id($value) >>

Type: C<String>

The ID of the backup.

=item * C<< $msg->service() >> / C<< $msg->service($value) >>

Type: C<String>

The relative resource name of a Metastore service in the form of
`projects/{project_id}/locations/{location_id}/services/{service_id}`

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when the backup was started.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp when the backup was completed.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Metastore::Logging::V1::ScheduledBackupLogEntry::State>)

Output only. The current state of the backup.

=item * C<< $msg->backup_size_bytes() >> / C<< $msg->backup_size_bytes($value) >>

Type: C<Int64>

Size of the backup data in bytes.

=item * C<< $msg->backup_location() >> / C<< $msg->backup_location($value) >>

Type: C<String>

A Cloud Storage URI of a folder, in the format
`gs://<bucket_name>/<path_inside_bucket>`.

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Message that provides (optional) details about the backup.

=back

=head3 Enum: ScheduledBackupLogEntry::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<IN_PROGRESS> => C<1>

=item * C<SUCCEEDED> => C<2>

=item * C<FAILED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
