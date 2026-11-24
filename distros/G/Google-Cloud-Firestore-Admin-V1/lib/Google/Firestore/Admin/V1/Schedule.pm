package Google::Firestore::Admin::V1::Schedule;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Dayofweek };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxL3NjaGVkdWxlLnByb3RvEhlnb29nbGUuZmly
ZXN0b3JlLmFkbWluLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aG2dvb2dsZS90eXBlL2RheW9md2Vl
ay5wcm90byKiBAoOQmFja3VwU2NoZWR1bGUSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEkAK
C2NyZWF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpj
cmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAogASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgp1cGRhdGVUaW1lEjcKCXJldGVudGlvbhgGIAEoCzIZLmdvb2dsZS5wcm90
b2J1Zi5EdXJhdGlvblIJcmV0ZW50aW9uElcKEGRhaWx5X3JlY3VycmVuY2UYByABKAsyKi5n
b29nbGUuZmlyZXN0b3JlLmFkbWluLnYxLkRhaWx5UmVjdXJyZW5jZUgAUg9kYWlseVJlY3Vy
cmVuY2USWgoRd2Vla2x5X3JlY3VycmVuY2UYCCABKAsyKy5nb29nbGUuZmlyZXN0b3JlLmFk
bWluLnYxLldlZWtseVJlY3VycmVuY2VIAFIQd2Vla2x5UmVjdXJyZW5jZTp36kF0CidmaXJl
c3RvcmUuZ29vZ2xlYXBpcy5jb20vQmFja3VwU2NoZWR1bGUSSXByb2plY3RzL3twcm9qZWN0
fS9kYXRhYmFzZXMve2RhdGFiYXNlfS9iYWNrdXBTY2hlZHVsZXMve2JhY2t1cF9zY2hlZHVs
ZX1CDAoKcmVjdXJyZW5jZSIRCg9EYWlseVJlY3VycmVuY2UiPAoQV2Vla2x5UmVjdXJyZW5j
ZRIoCgNkYXkYAiABKA4yFi5nb29nbGUudHlwZS5EYXlPZldlZWtSA2RheULcAQodY29tLmdv
b2dsZS5maXJlc3RvcmUuYWRtaW4udjFCDVNjaGVkdWxlUHJvdG9QAVo5Y2xvdWQuZ29vZ2xl
LmNvbS9nby9maXJlc3RvcmUvYXBpdjEvYWRtaW4vYWRtaW5wYjthZG1pbnBiogIER0NGU6oC
H0dvb2dsZS5DbG91ZC5GaXJlc3RvcmUuQWRtaW4uVjHKAh9Hb29nbGVcQ2xvdWRcRmlyZXN0
b3JlXEFkbWluXFYx6gIjR29vZ2xlOjpDbG91ZDo6RmlyZXN0b3JlOjpBZG1pbjo6VjFKxhUK
BhIEDgBeAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIgoJ
CgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKAoJCgIDAxIDFQApCgkKAgMEEgMWACUK
CAoBCBIDGAA8CgkKAgglEgMYADwKCAoBCBIDGQBQCgkKAggLEgMZAFAKCAoBCBIDGgAiCgkK
AggKEgMaACIKCAoBCBIDGwAuCgkKAggIEgMbAC4KCAoBCBIDHAA2CgkKAggBEgMcADYKCAoB
CBIDHQAiCgkKAggkEgMdACIKCAoBCBIDHgA9CgkKAggpEgMeAD0KCAoBCBIDHwA8CgkKAggt
EgMfADwKxwEKAgQAEgQlAE8BGroBIEEgYmFja3VwIHNjaGVkdWxlIGZvciBhIENsb3VkIEZp
cmVzdG9yZSBEYXRhYmFzZS4KCiBUaGlzIHJlc291cmNlIGlzIG93bmVkIGJ5IHRoZSBkYXRh
YmFzZSBpdCBpcyBiYWNraW5nIHVwLCBhbmQgaXMgZGVsZXRlZCBhbG9uZwogd2l0aCB0aGUg
ZGF0YWJhc2UuIFRoZSBhY3R1YWwgYmFja3VwcyBhcmUgbm90IHRob3VnaC4KCgoKAwQAARID
JQgWCgsKAwQABxIEJgIpBAoNCgUEAAedCBIEJgIpBAr0AQoEBAACABIDMgI+GuYBIE91dHB1
dCBvbmx5LiBUaGUgdW5pcXVlIGJhY2t1cCBzY2hlZHVsZSBpZGVudGlmaWVyIGFjcm9zcyBh
bGwgbG9jYXRpb25zIGFuZAogZGF0YWJhc2VzIGZvciB0aGUgZ2l2ZW4gcHJvamVjdC4KCiBU
aGlzIHdpbGwgYmUgYXV0by1hc3NpZ25lZC4KCiBGb3JtYXQgaXMKIGBwcm9qZWN0cy97cHJv
amVjdH0vZGF0YWJhc2VzL3tkYXRhYmFzZX0vYmFja3VwU2NoZWR1bGVzL3tiYWNrdXBfc2No
ZWR1bGV9YAoKDAoFBAACAAUSAzICCAoMCgUEAAIAARIDMgkNCgwKBQQAAgADEgMyEBEKDAoF
BAACAAgSAzISPQoPCggEAAIACJwIABIDMhM8CqwBCgQEAAIBEgQ4AjkyGp0BIE91dHB1dCBv
bmx5LiBUaGUgdGltZXN0YW1wIGF0IHdoaWNoIHRoaXMgYmFja3VwIHNjaGVkdWxlIHdhcyBj
cmVhdGVkIGFuZAogZWZmZWN0aXZlIHNpbmNlLgoKIE5vIGJhY2t1cHMgd2lsbCBiZSBjcmVh
dGVkIGZvciB0aGlzIHNjaGVkdWxlIGJlZm9yZSB0aGlzIHRpbWUuCgoMCgUEAAIBBhIDOAIb
CgwKBQQAAgEBEgM4HCcKDAoFBAACAQMSAzgqKwoMCgUEAAIBCBIDOQYxCg8KCAQAAgEInAgA
EgM5BzAKsAEKBAQAAgISBD4CPzIaoQEgT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAgYXQg
d2hpY2ggdGhpcyBiYWNrdXAgc2NoZWR1bGUgd2FzIG1vc3QgcmVjZW50bHkKIHVwZGF0ZWQu
IFdoZW4gYSBiYWNrdXAgc2NoZWR1bGUgaXMgZmlyc3QgY3JlYXRlZCwgdGhpcyBpcyB0aGUg
c2FtZSBhcwogY3JlYXRlX3RpbWUuCgoMCgUEAAICBhIDPgIbCgwKBQQAAgIBEgM+HCcKDAoF
BAACAgMSAz4qLAoMCgUEAAICCBIDPwYxCg8KCAQAAgIInAgAEgM/BzAKxgEKBAQAAgMSA0UC
KRq4ASBBdCB3aGF0IHJlbGF0aXZlIHRpbWUgaW4gdGhlIGZ1dHVyZSwgY29tcGFyZWQgdG8g
aXRzIGNyZWF0aW9uIHRpbWUsCiB0aGUgYmFja3VwIHNob3VsZCBiZSBkZWxldGVkLCBlLmcu
IGtlZXAgYmFja3VwcyBmb3IgNyBkYXlzLgoKIFRoZSBtYXhpbXVtIHN1cHBvcnRlZCByZXRl
bnRpb24gcGVyaW9kIGlzIDE0IHdlZWtzLgoKDAoFBAACAwYSA0UCGgoMCgUEAAIDARIDRRsk
CgwKBQQAAgMDEgNFJygKRgoEBAAIABIESAJOAxo4IEEgb25lb2YgZmllbGQgdG8gcmVwcmVz
ZW50IHdoZW4gYmFja3VwcyB3aWxsIGJlIHRha2VuLgoKDAoFBAAIAAESA0gIEgouCgQEAAIE
EgNKBCkaISBGb3IgYSBzY2hlZHVsZSB0aGF0IHJ1bnMgZGFpbHkuCgoMCgUEAAIEBhIDSgQT
CgwKBQQAAgQBEgNKFCQKDAoFBAACBAMSA0onKApBCgQEAAIFEgNNBCsaNCBGb3IgYSBzY2hl
ZHVsZSB0aGF0IHJ1bnMgd2Vla2x5IG9uIGEgc3BlY2lmaWMgZGF5LgoKDAoFBAACBQYSA00E
FAoMCgUEAAIFARIDTRUmCgwKBQQAAgUDEgNNKSoKWQoCBAESA1QAGhpOIFJlcHJlc2VudHMg
YSByZWN1cnJpbmcgc2NoZWR1bGUgdGhhdCBydW5zIGV2ZXJ5IGRheS4KCiBUaGUgdGltZSB6
b25lIGlzIFVUQy4KCgoKAwQBARIDVAgXCm8KAgQCEgRZAF4BGmMgUmVwcmVzZW50cyBhIHJl
Y3VycmluZyBzY2hlZHVsZSB0aGF0IHJ1bnMgb24gYSBzcGVjaWZpZWQgZGF5IG9mIHRoZSB3
ZWVrLgoKIFRoZSB0aW1lIHpvbmUgaXMgVVRDLgoKCgoDBAIBEgNZCBgKUAoEBAICABIDXQIg
GkMgVGhlIGRheSBvZiB3ZWVrIHRvIHJ1bi4KCiBEQVlfT0ZfV0VFS19VTlNQRUNJRklFRCBp
cyBub3QgYWxsb3dlZC4KCgwKBQQCAgAGEgNdAhcKDAoFBAICAAESA10YGwoMCgUEAgIAAxID
XR4fYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1::Schedule::BackupSchedule ===
    # Fields for BackupSchedule
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: retention Type: 11 (.google.protobuf.Duration)
    # Field: daily_recurrence Type: 11 (.google.firestore.admin.v1.DailyRecurrence)
    # Field: weekly_recurrence Type: 11 (.google.firestore.admin.v1.WeeklyRecurrence)

# === Message: Google::Firestore::Admin::V1::Schedule::DailyRecurrence ===
    # Fields for DailyRecurrence

# === Message: Google::Firestore::Admin::V1::Schedule::WeeklyRecurrence ===
    # Fields for WeeklyRecurrence
    # Field: day Type: 14 (.google.type.DayOfWeek)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1::Schedule - Compiled Protocol Buffers messages for google/firestore/admin/v1/schedule.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1::Schedule;

    my $msg = Google::Firestore::Admin::V1::Schedule::BackupSchedule->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        retention => $retention,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1::Schedule::BackupSchedule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1/schedule.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1::Schedule::BackupSchedule

A backup schedule for a Cloud Firestore Database.

This resource is owned by the database it is backing up, and is deleted along
with the database. The actual backups are not though.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique backup schedule identifier across all locations and
databases for the given project.

This will be auto-assigned.

Format is
`projects/{project}/databases/{database}/backupSchedules/{backup_schedule}`

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp at which this backup schedule was created and
effective since.

No backups will be created for this schedule before this time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp at which this backup schedule was most recently
updated. When a backup schedule is first created, this is the same as
create_time.

=item * C<< $msg->retention() >> / C<< $msg->retention($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

At what relative time in the future, compared to its creation time,
the backup should be deleted, e.g. keep backups for 7 days.

The maximum supported retention period is 14 weeks.

=item * C<< $msg->daily_recurrence() >> / C<< $msg->daily_recurrence($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Schedule::DailyRecurrence>)

For a schedule that runs daily.

=item * C<< $msg->weekly_recurrence() >> / C<< $msg->weekly_recurrence($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Schedule::WeeklyRecurrence>)

For a schedule that runs weekly on a specific day.

=back

=head2 Google::Firestore::Admin::V1::Schedule::DailyRecurrence

Represents a recurring schedule that runs every day.

The time zone is UTC.

Inherits from L<Protobuf::Message>.

=head2 Google::Firestore::Admin::V1::Schedule::WeeklyRecurrence

Represents a recurring schedule that runs on a specified day of the week.

The time zone is UTC.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->day() >> / C<< $msg->day($value) >>

Type: C<Enum> (L<Google::Type::DayOfWeek>)

The day of week to run.

DAY_OF_WEEK_UNSPECIFIED is not allowed.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1::Schedule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
