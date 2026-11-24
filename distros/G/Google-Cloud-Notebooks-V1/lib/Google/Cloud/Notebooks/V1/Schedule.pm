package Google::Cloud::Notebooks::V1::Schedule;

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
    eval { require Google::Cloud::Notebooks::V1::Execution };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxL3NjaGVkdWxlLnByb3RvEhlnb29nbGUuY2xv
dWQubm90ZWJvb2tzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvGilnb29nbGUvY2xvdWQvbm90ZWJvb2tzL3YxL2V4ZWN1
dGlvbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKIBgoIU2NoZWR1
bGUSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EED
UgtkaXNwbGF5TmFtZRIgCgtkZXNjcmlwdGlvbhgDIAEoCVILZGVzY3JpcHRpb24SPwoFc3Rh
dGUYBCABKA4yKS5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxLlNjaGVkdWxlLlN0YXRlUgVz
dGF0ZRIjCg1jcm9uX3NjaGVkdWxlGAUgASgJUgxjcm9uU2NoZWR1bGUSGwoJdGltZV96b25l
GAYgASgJUgh0aW1lWm9uZRJACgtjcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1
Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgIIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRJbChJleGVjdXRpb25f
dGVtcGxhdGUYCSABKAsyLC5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxLkV4ZWN1dGlvblRl
bXBsYXRlUhFleGVjdXRpb25UZW1wbGF0ZRJWChFyZWNlbnRfZXhlY3V0aW9ucxgKIAMoCzIk
Lmdvb2dsZS5jbG91ZC5ub3RlYm9va3MudjEuRXhlY3V0aW9uQgPgQQNSEHJlY2VudEV4ZWN1
dGlvbnMieAoFU3RhdGUSFQoRU1RBVEVfVU5TUEVDSUZJRUQQABILCgdFTkFCTEVEEAESCgoG
UEFVU0VEEAISDAoIRElTQUJMRUQQAxIRCg1VUERBVEVfRkFJTEVEEAQSEAoMSU5JVElBTEla
SU5HEAUSDAoIREVMRVRJTkcQBjpj6kFgCiFub3RlYm9va3MuZ29vZ2xlYXBpcy5jb20vU2No
ZWR1bGUSO3Byb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbi97bG9jYXRpb259L3NjaGVkdWxl
cy97c2NoZWR1bGV9Qm0KHWNvbS5nb29nbGUuY2xvdWQubm90ZWJvb2tzLnYxQg1TY2hlZHVs
ZVByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vbm90ZWJvb2tzL2FwaXYxL25vdGVib29r
c3BiO25vdGVib29rc3BiSvEcCgYSBA4AagEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAy
NSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJz
aW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4
Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBh
IGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xp
Y2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3
IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIg
dGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhP
VVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVz
cyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3Vh
Z2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExp
Y2Vuc2UuCgoICgECEgMQACIKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUADMKCQoC
AwMSAxUAKQoICgEIEgMXAFIKCQoCCAsSAxcAUgoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEI
EgMZAC4KCQoCCAgSAxkALgoICgEIEgMaADYKCQoCCAESAxoANgorCgIEABIEHQBqARofIFRo
ZSBkZWZpbml0aW9uIG9mIGEgc2NoZWR1bGUuCgoKCgMEAAESAx0IEAoLCgMEAAcSBB4CIQQK
DQoFBAAHnQgSBB4CIQQKIQoEBAAEABIEJAI+AxoTIFN0YXRlIG9mIHRoZSBqb2IuCgoMCgUE
AAQAARIDJAcMCiMKBgQABAACABIDJgQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoOCgcEAAQA
AgABEgMmBBUKDgoHBAAEAAIAAhIDJhgZCi8KBgQABAACARIDKQQQGiAgVGhlIGpvYiBpcyBl
eGVjdXRpbmcgbm9ybWFsbHkuCgoOCgcEAAQAAgEBEgMpBAsKDgoHBAAEAAIBAhIDKQ4PCogB
CgYEAAQAAgISAy4EDxp5IFRoZSBqb2IgaXMgcGF1c2VkIGJ5IHRoZSB1c2VyLiBJdCB3aWxs
IG5vdCBleGVjdXRlLiBBIHVzZXIgY2FuCiBpbnRlbnRpb25hbGx5IHBhdXNlIHRoZSBqb2Ig
dXNpbmcKIFtQYXVzZUpvYlJlcXVlc3RdW10uCgoOCgcEAAQAAgIBEgMuBAoKDgoHBAAEAAIC
AhIDLg0OCnQKBgQABAACAxIDMgQRGmUgVGhlIGpvYiBpcyBkaXNhYmxlZCBieSB0aGUgc3lz
dGVtIGR1ZSB0byBlcnJvci4gVGhlIHVzZXIKIGNhbm5vdCBkaXJlY3RseSBzZXQgYSBqb2Ig
dG8gYmUgZGlzYWJsZWQuCgoOCgcEAAQAAgMBEgMyBAwKDgoHBAAEAAIDAhIDMg8QCs8BCgYE
AAQAAgQSAzcEFhq/ASBUaGUgam9iIHN0YXRlIHJlc3VsdGluZyBmcm9tIGEgZmFpbGVkIFtD
bG91ZFNjaGVkdWxlci5VcGRhdGVKb2JdW10KIG9wZXJhdGlvbi4gVG8gcmVjb3ZlciBhIGpv
YiBmcm9tIHRoaXMgc3RhdGUsIHJldHJ5CiBbQ2xvdWRTY2hlZHVsZXIuVXBkYXRlSm9iXVtd
IHVudGlsIGEgc3VjY2Vzc2Z1bCByZXNwb25zZSBpcyByZWNlaXZlZC4KCg4KBwQABAACBAES
AzcEEQoOCgcEAAQAAgQCEgM3FBUKOAoGBAAEAAIFEgM6BBUaKSBUaGUgc2NoZWR1bGUgcmVz
b3VyY2UgaXMgYmVpbmcgY3JlYXRlZC4KCg4KBwQABAACBQESAzoEEAoOCgcEAAQAAgUCEgM6
ExQKOAoGBAAEAAIGEgM9BBEaKSBUaGUgc2NoZWR1bGUgcmVzb3VyY2UgaXMgYmVpbmcgZGVs
ZXRlZC4KCg4KBwQABAACBgESAz0EDAoOCgcEAAQAAgYCEgM9DxAKhAEKBAQAAgASA0ICPhp3
IE91dHB1dCBvbmx5LiBUaGUgbmFtZSBvZiB0aGlzIHNjaGVkdWxlLiBGb3JtYXQ6CiBgcHJv
amVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb259L3NjaGVkdWxlcy97c2No
ZWR1bGVfaWR9YAoKDAoFBAACAAUSA0ICCAoMCgUEAAIAARIDQgkNCgwKBQQAAgADEgNCEBEK
DAoFBAACAAgSA0ISPQoPCggEAAIACJwIABIDQhM8CpIBCgQEAAIBEgNHAkYahAEgT3V0cHV0
IG9ubHkuIERpc3BsYXkgbmFtZSB1c2VkIGZvciBVSSBwdXJwb3Nlcy4KIE5hbWUgY2FuIG9u
bHkgY29udGFpbiBhbHBoYW51bWVyaWMgY2hhcmFjdGVycywgaHlwaGVucyBgLWAsCiBhbmQg
dW5kZXJzY29yZXMgYF9gLgoKDAoFBAACAQUSA0cCCAoMCgUEAAIBARIDRwkVCgwKBQQAAgED
EgNHGBkKDAoFBAACAQgSA0caRQoPCggEAAIBCJwIABIDRxtECjcKBAQAAgISA0oCGRoqIEEg
YnJpZWYgZGVzY3JpcHRpb24gb2YgdGhpcyBlbnZpcm9ubWVudC4KCgwKBQQAAgIFEgNKAggK
DAoFBAACAgESA0oJFAoMCgUEAAICAxIDShcYCgsKBAQAAgMSA0wCEgoMCgUEAAIDBhIDTAIH
CgwKBQQAAgMBEgNMCA0KDAoFBAACAwMSA0wQEQrcAQoEBAACBBIDUgIbGs4BIENyb24tdGFi
IGZvcm1hdHRlZCBzY2hlZHVsZSBieSB3aGljaCB0aGUgam9iIHdpbGwgZXhlY3V0ZS4KIEZv
cm1hdDogbWludXRlLCBob3VyLCBkYXkgb2YgbW9udGgsIG1vbnRoLCBkYXkgb2Ygd2VlaywK
IGUuZy4gYDAgMCAqICogV0VEYCA9IGV2ZXJ5IFdlZG5lc2RheQogTW9yZSBleGFtcGxlczog
aHR0cHM6Ly9jcm9udGFiLmd1cnUvZXhhbXBsZXMuaHRtbAoKDAoFBAACBAUSA1ICCAoMCgUE
AAIEARIDUgkWCgwKBQQAAgQDEgNSGRoKyAMKBAQAAgUSA1wCFxq6AyBUaW1lem9uZSBvbiB3
aGljaCB0aGUgY3Jvbl9zY2hlZHVsZS4KIFRoZSB2YWx1ZSBvZiB0aGlzIGZpZWxkIG11c3Qg
YmUgYSB0aW1lIHpvbmUgbmFtZSBmcm9tIHRoZSB0eiBkYXRhYmFzZS4KIFRaIERhdGFiYXNl
OiBodHRwczovL2VuLndpa2lwZWRpYS5vcmcvd2lraS9MaXN0X29mX3R6X2RhdGFiYXNlX3Rp
bWVfem9uZXMKCiBOb3RlIHRoYXQgc29tZSB0aW1lIHpvbmVzIGluY2x1ZGUgYSBwcm92aXNp
b24gZm9yIGRheWxpZ2h0IHNhdmluZ3MgdGltZS4KIFRoZSBydWxlcyBmb3IgZGF5bGlnaHQg
c2F2aW5nIHRpbWUgYXJlIGRldGVybWluZWQgYnkgdGhlIGNob3NlbiB0ei4KIEZvciBVVEMg
dXNlIHRoZSBzdHJpbmcgInV0YyIuIElmIGEgdGltZSB6b25lIGlzIG5vdCBzcGVjaWZpZWQs
CiB0aGUgZGVmYXVsdCB3aWxsIGJlIGluIFVUQyAoYWxzbyBrbm93biBhcyBHTVQpLgoKDAoF
BAACBQUSA1wCCAoMCgUEAAIFARIDXAkSCgwKBQQAAgUDEgNcFRYKOgoEBAACBhIDXwJYGi0g
T3V0cHV0IG9ubHkuIFRpbWUgdGhlIHNjaGVkdWxlIHdhcyBjcmVhdGVkLgoKDAoFBAACBgYS
A18CGwoMCgUEAAIGARIDXxwnCgwKBQQAAgYDEgNfKisKDAoFBAACBggSA18sVwoPCggEAAIG
CJwIABIDXy1WCj8KBAQAAgcSA2ICWBoyIE91dHB1dCBvbmx5LiBUaW1lIHRoZSBzY2hlZHVs
ZSB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACBwYSA2ICGwoMCgUEAAIHARIDYhwnCgwKBQQA
AgcDEgNiKisKDAoFBAACBwgSA2IsVwoPCggEAAIHCJwIABIDYi1WCkoKBAQAAggSA2UCKxo9
IE5vdGVib29rIEV4ZWN1dGlvbiBUZW1wbGF0ZSBjb3JyZXNwb25kaW5nIHRvIHRoaXMgc2No
ZWR1bGUuCgoMCgUEAAIIBhIDZQITCgwKBQQAAggBEgNlFCYKDAoFBAACCAMSA2UpKgp5CgQE
AAIJEgNpAlgabCBPdXRwdXQgb25seS4gVGhlIG1vc3QgcmVjZW50IGV4ZWN1dGlvbiBuYW1l
cyB0cmlnZ2VyZWQgZnJvbSB0aGlzIHNjaGVkdWxlIGFuZCB0aGVpcgogY29ycmVzcG9uZGlu
ZyBzdGF0ZXMuCgoMCgUEAAIJBBIDaQIKCgwKBQQAAgkGEgNpCxQKDAoFBAACCQESA2kVJgoM
CgUEAAIJAxIDaSkrCgwKBQQAAgkIEgNpLFcKDwoIBAACCQicCAASA2ktVmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Notebooks::V1::Schedule::Schedule ===
    # Fields for Schedule
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: state Type: 14 (.google.cloud.notebooks.v1.Schedule.State)
    # Field: cron_schedule Type: 9 ()
    # Field: time_zone Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: execution_template Type: 11 (.google.cloud.notebooks.v1.ExecutionTemplate)
    # Field: recent_executions Type: 11 (.google.cloud.notebooks.v1.Execution)

# Enum: Schedule::State
our $Schedule_STATE_UNSPECIFIED = 0;
our $Schedule_ENABLED = 1;
our $Schedule_PAUSED = 2;
our $Schedule_DISABLED = 3;
our $Schedule_UPDATE_FAILED = 4;
our $Schedule_INITIALIZING = 5;
our $Schedule_DELETING = 6;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Notebooks::V1::Schedule - Compiled Protocol Buffers messages for google/cloud/notebooks/v1/schedule.proto

=head1 SYNOPSIS

    use Google::Cloud::Notebooks::V1::Schedule;

    my $msg = Google::Cloud::Notebooks::V1::Schedule::Schedule->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        state => $state,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Notebooks::V1::Schedule::Schedule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/notebooks/v1/schedule.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Notebooks::V1::Schedule::Schedule

The definition of a schedule.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The name of this schedule. Format:
`projects/{project_id}/locations/{location}/schedules/{schedule_id}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name used for UI purposes.
Name can only contain alphanumeric characters, hyphens `-`,
and underscores `_`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

A brief description of this environment.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Notebooks::V1::Schedule::State>)

=item * C<< $msg->cron_schedule() >> / C<< $msg->cron_schedule($value) >>

Type: C<String>

Cron-tab formatted schedule by which the job will execute.
Format: minute, hour, day of month, month, day of week,
e.g. `0 0 * * WED` = every Wednesday
More examples: https://crontab.guru/examples.html

=item * C<< $msg->time_zone() >> / C<< $msg->time_zone($value) >>

Type: C<String>

Timezone on which the cron_schedule.
The value of this field must be a time zone name from the tz database.
TZ Database: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

Note that some time zones include a provision for daylight savings time.
The rules for daylight saving time are determined by the chosen tz.
For UTC use the string "utc". If a time zone is not specified,
the default will be in UTC (also known as GMT).

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the schedule was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Time the schedule was last updated.

=item * C<< $msg->execution_template() >> / C<< $msg->execution_template($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Execution::ExecutionTemplate>)

Notebook Execution Template corresponding to this schedule.

=item * C<< $msg->recent_executions() >> / C<< $msg->recent_executions($value) >>

Type: C<Message> (L<Google::Cloud::Notebooks::V1::Execution::Execution>)

Output only. The most recent execution names triggered from this schedule and their
corresponding states.

=back

=head3 Enum: Schedule::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<PAUSED> => C<2>

=item * C<DISABLED> => C<3>

=item * C<UPDATE_FAILED> => C<4>

=item * C<INITIALIZING> => C<5>

=item * C<DELETING> => C<6>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Notebooks::V1::Schedule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
