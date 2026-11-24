package Google::Cloud::Backupdr::V1beta::BackupvaultBa;

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
CjFnb29nbGUvY2xvdWQvYmFja3VwZHIvdjFiZXRhL2JhY2t1cHZhdWx0X2JhLnByb3RvEhxn
b29nbGUuY2xvdWQuYmFja3VwZHIudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9y
LnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIrcDCh9CYWNrdXBBcHBs
aWFuY2VCYWNrdXBQcm9wZXJ0aWVzEi0KDWdlbmVyYXRpb25faWQYASABKAVCA+BBA0gAUgxn
ZW5lcmF0aW9uSWSIAQESSQoNZmluYWxpemVfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA0gBUgxmaW5hbGl6ZVRpbWWIAQESXwoZcmVjb3ZlcnlfcmFuZ2Vf
c3RhcnRfdGltZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAUgCUhZy
ZWNvdmVyeVJhbmdlU3RhcnRUaW1liAEBElsKF3JlY292ZXJ5X3JhbmdlX2VuZF90aW1lGAQg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEBSANSFHJlY292ZXJ5UmFuZ2VF
bmRUaW1liAEBQhAKDl9nZW5lcmF0aW9uX2lkQhAKDl9maW5hbGl6ZV90aW1lQhwKGl9yZWNv
dmVyeV9yYW5nZV9zdGFydF90aW1lQhoKGF9yZWNvdmVyeV9yYW5nZV9lbmRfdGltZULWAQog
Y29tLmdvb2dsZS5jbG91ZC5iYWNrdXBkci52MWJldGFCEkJhY2t1cHZhdWx0QmFQcm90b1AB
WjxjbG91ZC5nb29nbGUuY29tL2dvL2JhY2t1cGRyL2FwaXYxYmV0YS9iYWNrdXBkcnBiO2Jh
Y2t1cGRycGKqAhxHb29nbGUuQ2xvdWQuQmFja3VwRFIuVjFCZXRhygIcR29vZ2xlXENsb3Vk
XEJhY2t1cERSXFYxYmV0YeoCH0dvb2dsZTo6Q2xvdWQ6OkJhY2t1cERSOjpWMWJldGFKvwwK
BhIEDgAwAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoJ
CgIDABIDEgApCgkKAgMBEgMTACkKCAoBCBIDFQA5CgkKAgglEgMVADkKCAoBCBIDFgBTCgkK
AggLEgMWAFMKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAAzCgkKAggIEgMYADMKCAoB
CBIDGQA5CgkKAggBEgMZADkKCAoBCBIDGgA5CgkKAggpEgMaADkKCAoBCBIDGwA4CgkKAggt
EgMbADgKYQoCBAASBB8AMAEaVSBCYWNrdXBBcHBsaWFuY2VCYWNrdXBQcm9wZXJ0aWVzIHJl
cHJlc2VudHMgQmFja3VwRFIgYmFja3VwIGFwcGxpYW5jZSdzCiBwcm9wZXJ0aWVzLgoKCgoD
BAABEgMfCCcKYAoEBAACABIDIgJPGlMgT3V0cHV0IG9ubHkuIFRoZSBudW1lcmljIGdlbmVy
YXRpb24gSUQgb2YgdGhlIGJhY2t1cCAobW9ub3RvbmljYWxseQogaW5jcmVhc2luZykuCgoM
CgUEAAIABBIDIgIKCgwKBQQAAgAFEgMiCxAKDAoFBAACAAESAyIRHgoMCgUEAAIAAxIDIiEi
CgwKBQQAAgAIEgMiI04KDwoIBAACAAicCAASAyIkTQpwCgQEAAIBEgQmAicyGmIgT3V0cHV0
IG9ubHkuIFRoZSB0aW1lIHdoZW4gdGhpcyBiYWNrdXAgb2JqZWN0IHdhcyBmaW5hbGl6ZWQg
KGlmIG5vbmUsCiBiYWNrdXAgaXMgbm90IGZpbmFsaXplZCkuCgoMCgUEAAIBBBIDJgIKCgwK
BQQAAgEGEgMmCyQKDAoFBAACAQESAyYlMgoMCgUEAAIBAxIDJjU2CgwKBQQAAgEIEgMnBjEK
DwoIBAACAQicCAASAycHMApSCgQEAAICEgQqAisvGkQgT3B0aW9uYWwuIFRoZSBlYXJsaWVz
dCB0aW1lc3RhbXAgb2YgZGF0YSBhdmFpbGFibGUgaW4gdGhpcyBCYWNrdXAuCgoMCgUEAAIC
BBIDKgIKCgwKBQQAAgIGEgMqCyQKDAoFBAACAgESAyolPgoMCgUEAAICAxIDKkFCCgwKBQQA
AgIIEgMrBi4KDwoIBAACAgicCAASAysHLQpQCgQEAAIDEgQuAi8vGkIgT3B0aW9uYWwuIFRo
ZSBsYXRlc3QgdGltZXN0YW1wIG9mIGRhdGEgYXZhaWxhYmxlIGluIHRoaXMgQmFja3VwLgoK
DAoFBAACAwQSAy4CCgoMCgUEAAIDBhIDLgskCgwKBQQAAgMBEgMuJTwKDAoFBAACAwMSAy4/
QAoMCgUEAAIDCBIDLwYuCg8KCAQAAgMInAgAEgMvBy1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Backupdr::V1beta::BackupvaultBa::BackupApplianceBackupProperties ===
    # Fields for BackupApplianceBackupProperties
    # Field: generation_id Type: 5 ()
    # Field: finalize_time Type: 11 (.google.protobuf.Timestamp)
    # Field: recovery_range_start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: recovery_range_end_time Type: 11 (.google.protobuf.Timestamp)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Backupdr::V1beta::BackupvaultBa - Compiled Protocol Buffers messages for google/cloud/backupdr/v1beta/backupvault_ba.proto

=head1 SYNOPSIS

    use Google::Cloud::Backupdr::V1beta::BackupvaultBa;

    my $msg = Google::Cloud::Backupdr::V1beta::BackupvaultBa::BackupApplianceBackupProperties->new({
        generation_id => $generation_id,
        finalize_time => $finalize_time,
        recovery_range_start_time => $recovery_range_start_time,
        recovery_range_end_time => $recovery_range_end_time,
    });

    # Read or update a field
    my $val = $msg->generation_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Backupdr::V1beta::BackupvaultBa::BackupApplianceBackupProperties->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/backupdr/v1beta/backupvault_ba.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Backupdr::V1beta::BackupvaultBa::BackupApplianceBackupProperties

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Backupdr::V1beta::BackupvaultBa::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
