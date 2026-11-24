package Google::Cloud::Gkebackup::Logging::V1::LoggedBackup;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvZ2tlYmFja3VwL2xvZ2dpbmcvdjEvbG9nZ2VkX2JhY2t1cC5wcm90
bxIhZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC5sb2dnaW5nLnYxIuMDCgxMb2dnZWRCYWNrdXAS
UwoGbGFiZWxzGAEgAygLMjsuZ29vZ2xlLmNsb3VkLmdrZWJhY2t1cC5sb2dnaW5nLnYxLkxv
Z2dlZEJhY2t1cC5MYWJlbHNFbnRyeVIGbGFiZWxzEigKEGRlbGV0ZV9sb2NrX2RheXMYAiAB
KAVSDmRlbGV0ZUxvY2tEYXlzEh8KC3JldGFpbl9kYXlzGAMgASgFUgpyZXRhaW5EYXlzEiAK
C2Rlc2NyaXB0aW9uGAQgASgJUgtkZXNjcmlwdGlvbhJLCgVzdGF0ZRgFIAEoDjI1Lmdvb2ds
ZS5jbG91ZC5na2ViYWNrdXAubG9nZ2luZy52MS5Mb2dnZWRCYWNrdXAuU3RhdGVSBXN0YXRl
EiEKDHN0YXRlX3JlYXNvbhgGIAEoCVILc3RhdGVSZWFzb24aOQoLTGFiZWxzRW50cnkSEAoD
a2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJmCgVTdGF0ZRIVChFT
VEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESDwoLSU5fUFJPR1JFU1MQAhINCglT
VUNDRUVERUQQAxIKCgZGQUlMRUQQBBIMCghERUxFVElORxAFQukBCiFnb29nbGUuY2xvdWQu
Z2tlYmFja3VwLmxvZ2dpbmcudjFCEUxvZ2dlZEJhY2t1cFByb3RvUAFaP2Nsb3VkLmdvb2ds
ZS5jb20vZ28vZ2tlYmFja3VwL2xvZ2dpbmcvYXBpdjEvbG9nZ2luZ3BiO2xvZ2dpbmdwYqoC
IUdvb2dsZS5DbG91ZC5Ha2VCYWNrdXAuTG9nZ2luZy5WMcoCIUdvb2dsZVxDbG91ZFxHa2VC
YWNrdXBcTG9nZ2luZ1xWMeoCJUdvb2dsZTo6Q2xvdWQ6OkdrZUJhY2t1cDo6TG9nZ2luZzo6
VjFK0BMKBhIEDgBJAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAKgoICgEIEgMSAD4KCQoCCCUSAxIAPgoICgEIEgMTAFYKCQoCCAsSAxMAVgoICgEIEgMU
ACIKCQoCCAoSAxQAIgoICgEIEgMVADIKCQoCCAgSAxUAMgoICgEIEgMWADoKCQoCCAESAxYA
OgoICgEIEgMXAD8KCQoCCCkSAxcAPwoICgEIEgMYAD4KCQoCCC0SAxgAPgq6AQoCBAASBB0A
SQEarQEgQmFja3VwIGFzIHN0b3JlZCBpbiBQbGF0Zm9ybSBsb2cuIEl0J3MgdXNlZCB0byBs
b2cgdGhlIGRldGFpbHMgb2YKIGEgY3JlYXRlQmFja3VwL3VwZGF0ZUJhY2t1cCByZXF1ZXN0
LCBzbyBvbmx5IGZpZWxkcyB0aGF0IGNhbiBiZSB0YWtlbgogZnJvbSBBUEkgY2FsbHMgYXJl
IGluY2x1ZGVkIGhlcmUuCgoKCgMEAAESAx0IFAoVCgQEAAQAEgQfAjQDGgcgU3RhdGUKCgwK
BQQABAABEgMfBwwKSAoGBAAEAAIAEgMhBBoaOSBUaGUgQmFja3VwIHJlc291cmNlIGlzIGlu
IHRoZSBwcm9jZXNzIG9mIGJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQAAgABEgMhBBUKDgoHBAAE
AAIAAhIDIRgZCpMBCgYEAAQAAgESAyUEERqDASBUaGUgQmFja3VwIHJlc291cmNlIGhhcyBi
ZWVuIGNyZWF0ZWQgYW5kIHRoZSBhc3NvY2lhdGVkIEJhY2t1cEpvYgogS3ViZXJuZXRlcyBy
ZXNvdXJjZSBoYXMgYmVlbiBpbmplY3RlZCBpbnRvIHRoZSBzb3VyY2UgY2x1c3Rlci4KCg4K
BwQABAACAQESAyUEDAoOCgcEAAQAAgECEgMlDxAKXgoGBAAEAAICEgMpBBQaTyBUaGUgZ2tl
YmFja3VwIGFnZW50IGluIHRoZSBjbHVzdGVyIGhhcyBiZWd1biBleGVjdXRpbmcgdGhlIGJh
Y2t1cAogb3BlcmF0aW9uLgoKDgoHBAAEAAICARIDKQQPCg4KBwQABAACAgISAykSEwpBCgYE
AAQAAgMSAywEEhoyIFRoZSBiYWNrdXAgb3BlcmF0aW9uIGhhcyBjb21wbGV0ZWQgc3VjY2Vz
c2Z1bGx5LgoKDgoHBAAEAAIDARIDLAQNCg4KBwQABAACAwISAywQEQoxCgYEAAQAAgQSAy8E
DxoiIFRoZSBiYWNrdXAgb3BlcmF0aW9uIGhhcyBmYWlsZWQuCgoOCgcEAAQAAgQBEgMvBAoK
DgoHBAAEAAIEAhIDLw0OCmkKBgQABAACBRIDMwQRGlogVGhpcyBCYWNrdXAgcmVzb3VyY2Ug
KGFuZCBpdHMgYXNzb2NpYXRlZCBhcnRpZmFjdHMpIGlzIGluIHRoZSBwcm9jZXNzCiBvZiBi
ZWluZyBkZWxldGVkLgoKDgoHBAAEAAIFARIDMwQMCg4KBwQABAACBQISAzMPEAo3CgQEAAIA
EgM3AiEaKiBBIHNldCBvZiBjdXN0b20gbGFiZWxzIHN1cHBsaWVkIGJ5IHVzZXIuCgoMCgUE
AAIABhIDNwIVCgwKBQQAAgABEgM3FhwKDAoFBAACAAMSAzcfIAqIAQoEBAACARIDOwIdGnsg
ZGVsZXRlX2xvY2tfZGF5cyBzcGVjaWZpZXMgdGhlIG51bWJlciBvZiBkYXlzIGZyb20gdGhl
IGNyZWF0ZV90aW1lIG9mIHRoaXMKIEJhY2t1cCBiZWZvcmUgd2hpY2ggZGVsZXRpb24gd2ls
bCBiZSBibG9ja2VkLgoKDAoFBAACAQUSAzsCBwoMCgUEAAIBARIDOwgYCgwKBQQAAgEDEgM7
GxwKkwEKBAQAAgISAz8CGBqFASByZXRhaW5fZGF5cyBzcGVjaWZpZXMgdGhlIGRlc2lyZWQg
bnVtYmVyIG9mIGRheXMgZnJvbSB0aGUgY3JlYXRlX3RpbWUgb2YKIHRoaXMgQmFja3VwIGFm
dGVyIHdoaWNoIGl0IHdpbGwgYmUgYXV0b21hdGljYWxseSBkZWxldGVkLgoKDAoFBAACAgUS
Az8CBwoMCgUEAAICARIDPwgTCgwKBQQAAgIDEgM/FhcKQQoEBAACAxIDQgIZGjQgVXNlciBz
cGVjaWZpZWQgZGVzY3JpcHRpdmUgc3RyaW5nIGZvciB0aGlzIEJhY2t1cC4KCgwKBQQAAgMF
EgNCAggKDAoFBAACAwESA0IJFAoMCgUEAAIDAxIDQhcYCioKBAQAAgQSA0UCEhodIEN1cnJl
bnQgc3RhdGUgb2YgdGhlIEJhY2t1cAoKDAoFBAACBAYSA0UCBwoMCgUEAAIEARIDRQgNCgwK
BQQAAgQDEgNFEBEKVgoEBAACBRIDSAIaGkkgSHVtYW4tcmVhZGFibGUgZGVzY3JpcHRpb24g
b2Ygd2h5IHRoZSBiYWNrdXAgaXMgaW4gdGhlIGN1cnJlbnQgYHN0YXRlYC4KCgwKBQQAAgUF
EgNIAggKDAoFBAACBQESA0gJFQoMCgUEAAIFAxIDSBgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::Logging::V1::LoggedBackup::LoggedBackup ===
    # Fields for LoggedBackup
    # Field: labels Type: 11 (.google.cloud.gkebackup.logging.v1.LoggedBackup.LabelsEntry)
    # Field: delete_lock_days Type: 5 ()
    # Field: retain_days Type: 5 ()
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.gkebackup.logging.v1.LoggedBackup.State)
    # Field: state_reason Type: 9 ()

# Enum: LoggedBackup::State
our $LoggedBackup_STATE_UNSPECIFIED = 0;
our $LoggedBackup_CREATING = 1;
our $LoggedBackup_IN_PROGRESS = 2;
our $LoggedBackup_SUCCEEDED = 3;
our $LoggedBackup_FAILED = 4;
our $LoggedBackup_DELETING = 5;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedBackup - Compiled Protocol Buffers messages for google/cloud/gkebackup/logging/v1/logged_backup.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::Logging::V1::LoggedBackup;

    my $msg = Google::Cloud::Gkebackup::Logging::V1::LoggedBackup::LoggedBackup->new({
        labels => $labels,
        delete_lock_days => $delete_lock_days,
        retain_days => $retain_days,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->labels();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::Logging::V1::LoggedBackup::LoggedBackup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/logging/v1/logged_backup.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::Logging::V1::LoggedBackup::LoggedBackup

Backup as stored in Platform log. It's used to log the details of
a createBackup/updateBackup request, so only fields that can be taken
from API calls are included here.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackup::LoggedBackup::LabelsEntry>)

A set of custom labels supplied by user.

=item * C<< $msg->delete_lock_days() >> / C<< $msg->delete_lock_days($value) >>

Type: C<Int32>

delete_lock_days specifies the number of days from the create_time of this
Backup before which deletion will be blocked.

=item * C<< $msg->retain_days() >> / C<< $msg->retain_days($value) >>

Type: C<Int32>

retain_days specifies the desired number of days from the create_time of
this Backup after which it will be automatically deleted.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User specified descriptive string for this Backup.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackup::State>)

Current state of the Backup

=item * C<< $msg->state_reason() >> / C<< $msg->state_reason($value) >>

Type: C<String>

Human-readable description of why the backup is in the current `state`.

=back

=head3 Enum: LoggedBackup::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<IN_PROGRESS> => C<2>

=item * C<SUCCEEDED> => C<3>

=item * C<FAILED> => C<4>

=item * C<DELETING> => C<5>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::Logging::V1::LoggedBackup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
