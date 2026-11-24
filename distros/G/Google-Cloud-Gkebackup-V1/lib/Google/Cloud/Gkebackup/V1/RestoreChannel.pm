package Google::Cloud::Gkebackup::V1::RestoreChannel;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZ2tlYmFja3VwL3YxL3Jlc3RvcmVfY2hhbm5lbC5wcm90bxIZZ29v
Z2xlLmNsb3VkLmdrZWJhY2t1cC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxobZ29vZ2xlL2FwaS9maWVsZF9pbmZvLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnBy
b3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIqsFCg5SZXN0b3JlQ2hhbm5l
bBIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWUSNwoTZGVzdGluYXRpb25fcHJvamVjdBgCIAEo
CUIG4EEF4EECUhJkZXN0aW5hdGlvblByb2plY3QSHQoDdWlkGAMgASgJQgvijM/XCAIIAeBB
A1IDdWlkEkAKC2NyZWF0ZV90aW1lGAQgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lElIKBmxhYmVscxgGIAMoCzI1Lmdvb2ds
ZS5jbG91ZC5na2ViYWNrdXAudjEuUmVzdG9yZUNoYW5uZWwuTGFiZWxzRW50cnlCA+BBAVIG
bGFiZWxzEiUKC2Rlc2NyaXB0aW9uGAcgASgJQgPgQQFSC2Rlc2NyaXB0aW9uEhcKBGV0YWcY
CCABKAlCA+BBA1IEZXRhZxI5ChZkZXN0aW5hdGlvbl9wcm9qZWN0X2lkGAkgASgJQgPgQQNS
FGRlc3RpbmF0aW9uUHJvamVjdElkGjkKC0xhYmVsc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5
EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6mQHqQZUBCidna2ViYWNrdXAuZ29vZ2xlYXBp
cy5jb20vUmVzdG9yZUNoYW5uZWwSSXByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9yZXN0b3JlQ2hhbm5lbHMve3Jlc3RvcmVfY2hhbm5lbH0qD3Jlc3RvcmVDaGFu
bmVsczIOcmVzdG9yZUNoYW5uZWxCygEKHWNvbS5nb29nbGUuY2xvdWQuZ2tlYmFja3VwLnYx
QhNSZXN0b3JlQ2hhbm5lbFByb3RvUAFaO2Nsb3VkLmdvb2dsZS5jb20vZ28vZ2tlYmFja3Vw
L2FwaXYxL2drZWJhY2t1cHBiO2drZWJhY2t1cHBiqgIZR29vZ2xlLkNsb3VkLkdrZUJhY2t1
cC5WMcoCGUdvb2dsZVxDbG91ZFxHa2VCYWNrdXBcVjHqAhxHb29nbGU6OkNsb3VkOjpHa2VC
YWNrdXA6OlYxSu0ZCgYSBA4AWwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
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
CgoICgECEgMQACIKCQoCAwASAxIAKQoJCgIDARIDEwAlCgkKAgMCEgMUACMKCQoCAwMSAxUA
KQoICgEIEgMXADYKCQoCCCUSAxcANgoICgEIEgMYAFIKCQoCCAsSAxgAUgoICgEIEgMZACIK
CQoCCAoSAxkAIgoICgEIEgMaADQKCQoCCAgSAxoANAoICgEIEgMbADYKCQoCCAESAxsANgoI
CgEIEgMcADYKCQoCCCkSAxwANgoICgEIEgMdADUKCQoCCC0SAx0ANQrjAQoCBAASBCMAWwEa
1gEgQSBSZXN0b3JlQ2hhbm5lbCBpbXBvc2VzIGNvbnN0cmFpbnRzIG9uIHdoZXJlIGJhY2t1
cHMgY2FuIGJlIHJlc3RvcmVkLgogVGhlIFJlc3RvcmVDaGFubmVsIHNob3VsZCBiZSBpbiB0
aGUgc2FtZSBwcm9qZWN0IGFuZCByZWdpb24KIGFzIHRoZSBiYWNrdXBzLiBUaGUgYmFja3Vw
cyBjYW4gb25seSBiZSByZXN0b3JlZCBpbiB0aGUKIGBkZXN0aW5hdGlvbl9wcm9qZWN0YC4K
CgoKAwQAARIDIwgWCgsKAwQABxIEJAIpBAoNCgUEAAedCBIEJAIpBAp2CgQEAAIAEgMtAj0a
aSBJZGVudGlmaWVyLiBUaGUgZnVsbHkgcXVhbGlmaWVkIG5hbWUgb2YgdGhlIFJlc3RvcmVD
aGFubmVsLgogYHByb2plY3RzLyovbG9jYXRpb25zLyovcmVzdG9yZUNoYW5uZWxzLypgCgoM
CgUEAAIABRIDLQIICgwKBQQAAgABEgMtCQ0KDAoFBAACAAMSAy0QEQoMCgUEAAIACBIDLRI8
Cg8KCAQAAgAInAgAEgMtEzsKnwEKBAQAAgESBDECNAQakAEgUmVxdWlyZWQuIEltbXV0YWJs
ZS4gVGhlIHByb2plY3QgaW50byB3aGljaCB0aGUgYmFja3VwcyB3aWxsIGJlIHJlc3RvcmVk
LgogVGhlIGZvcm1hdCBpcyBgcHJvamVjdHMve3Byb2plY3RJZH1gIG9yIGBwcm9qZWN0cy97
cHJvamVjdE51bWJlcn1gLgoKDAoFBAACAQUSAzECCAoMCgUEAAIBARIDMQkcCgwKBQQAAgED
EgMxHyAKDQoFBAACAQgSBDEhNAMKDwoIBAACAQicCAASAzIEKwoPCggEAAIBCJwIARIDMwQq
CpcBCgQEAAICEgQ4AjsEGogBIE91dHB1dCBvbmx5LiBTZXJ2ZXIgZ2VuZXJhdGVkIGdsb2Jh
bCB1bmlxdWUgaWRlbnRpZmllciBvZgogW1VVSURdKGh0dHBzOi8vZW4ud2lraXBlZGlhLm9y
Zy93aWtpL1VuaXZlcnNhbGx5X3VuaXF1ZV9pZGVudGlmaWVyKSBmb3JtYXQuCgoMCgUEAAIC
BRIDOAIICgwKBQQAAgIBEgM4CQwKDAoFBAACAgMSAzgPEAoNCgUEAAICCBIEOBE7AwoSCgsE
AAICCMzx+YoBARIDOQQqCg8KCAQAAgIInAgAEgM6BC0KUAoEBAACAxIEPgI/MhpCIE91dHB1
dCBvbmx5LiBUaGUgdGltZXN0YW1wIHdoZW4gdGhpcyBSZXN0b3JlQ2hhbm5lbCB3YXMgY3Jl
YXRlZC4KCgwKBQQAAgMGEgM+AhsKDAoFBAACAwESAz4cJwoMCgUEAAIDAxIDPiorCgwKBQQA
AgMIEgM/BjEKDwoIBAACAwicCAASAz8HMApVCgQEAAIEEgRCAkMyGkcgT3V0cHV0IG9ubHku
IFRoZSB0aW1lc3RhbXAgd2hlbiB0aGlzIFJlc3RvcmVDaGFubmVsIHdhcyBsYXN0IHVwZGF0
ZWQuCgoMCgUEAAIEBhIDQgIbCgwKBQQAAgQBEgNCHCcKDAoFBAACBAMSA0IqKwoMCgUEAAIE
CBIDQwYxCg8KCAQAAgQInAgAEgNDBzAKQQoEBAACBRIDRgJKGjQgT3B0aW9uYWwuIEEgc2V0
IG9mIGN1c3RvbSBsYWJlbHMgc3VwcGxpZWQgYnkgdXNlci4KCgwKBQQAAgUGEgNGAhUKDAoF
BAACBQESA0YWHAoMCgUEAAIFAxIDRh8gCgwKBQQAAgUIEgNGIUkKDwoIBAACBQicCAASA0Yi
SApTCgQEAAIGEgNJAkIaRiBPcHRpb25hbC4gVXNlciBzcGVjaWZpZWQgZGVzY3JpcHRpdmUg
c3RyaW5nIGZvciB0aGlzIFJlc3RvcmVDaGFubmVsLgoKDAoFBAACBgUSA0kCCAoMCgUEAAIG
ARIDSQkUCgwKBQQAAgYDEgNJFxgKDAoFBAACBggSA0kZQQoPCggEAAIGCJwIABIDSRpACtIE
CgQEAAIHEgNUAj4axAQgT3V0cHV0IG9ubHkuIGBldGFnYCBpcyB1c2VkIGZvciBvcHRpbWlz
dGljIGNvbmN1cnJlbmN5IGNvbnRyb2wgYXMgYSB3YXkgdG8KIGhlbHAgcHJldmVudCBzaW11
bHRhbmVvdXMgdXBkYXRlcyBvZiBhIFJlc3RvcmVDaGFubmVsIGZyb20gb3ZlcndyaXRpbmcg
ZWFjaAogb3RoZXIuIEl0IGlzIHN0cm9uZ2x5IHN1Z2dlc3RlZCB0aGF0IHN5c3RlbXMgbWFr
ZSB1c2Ugb2YgdGhlICdldGFnJyBpbiB0aGUKIHJlYWQtbW9kaWZ5LXdyaXRlIGN5Y2xlIHRv
IHBlcmZvcm0gUmVzdG9yZUNoYW5uZWwgdXBkYXRlcyBpbiBvcmRlciB0bwogYXZvaWQgcmFj
ZSBjb25kaXRpb25zOiBBbiBgZXRhZ2AgaXMgcmV0dXJuZWQgaW4gdGhlIHJlc3BvbnNlIHRv
CiBgR2V0UmVzdG9yZUNoYW5uZWxgLCBhbmQgc3lzdGVtcyBhcmUgZXhwZWN0ZWQgdG8gcHV0
IHRoYXQgZXRhZyBpbiB0aGUKIHJlcXVlc3QgdG8gYFVwZGF0ZVJlc3RvcmVDaGFubmVsYCBv
ciBgRGVsZXRlUmVzdG9yZUNoYW5uZWxgIHRvCiBlbnN1cmUgdGhhdCB0aGVpciBjaGFuZ2Ug
d2lsbCBiZSBhcHBsaWVkIHRvIHRoZSBzYW1lIHZlcnNpb24gb2YgdGhlCiByZXNvdXJjZS4K
CgwKBQQAAgcFEgNUAggKDAoFBAACBwESA1QJDQoMCgUEAAIHAxIDVBARCgwKBQQAAgcIEgNU
Ej0KDwoIBAACBwicCAASA1QTPArKAQoEBAACCBIDWgJQGrwBIE91dHB1dCBvbmx5LiBUaGUg
cHJvamVjdF9pZCB3aGVyZSBiYWNrdXBzIHdpbGwgYmUgcmVzdG9yZWQuCiBFeGFtcGxlIFBy
b2plY3QgSUQ6ICJteS1wcm9qZWN0LWlkIi4KIFRoaXMgd2lsbCBiZSBhbiBPVVRQVVRfT05M
WSBmaWVsZCB0byByZXR1cm4gdGhlIHByb2plY3RfaWQgb2YgdGhlCiBkZXN0aW5hdGlvbiBw
cm9qZWN0LgoKDAoFBAACCAUSA1oCCAoMCgUEAAIIARIDWgkfCgwKBQQAAggDEgNaIiMKDAoF
BAACCAgSA1okTwoPCggEAAIICJwIABIDWiVOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel ===
    # Fields for RestoreChannel
    # Field: name Type: 9 ()
    # Field: destination_project Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.gkebackup.v1.RestoreChannel.LabelsEntry)
    # Field: description Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: destination_project_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Gkebackup::V1::RestoreChannel - Compiled Protocol Buffers messages for google/cloud/gkebackup/v1/restore_channel.proto

=head1 SYNOPSIS

    use Google::Cloud::Gkebackup::V1::RestoreChannel;

    my $msg = Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel->new({
        name => $name,
        destination_project => $destination_project,
        uid => $uid,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/gkebackup/v1/restore_channel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel

A RestoreChannel imposes constraints on where backups can be restored.
The RestoreChannel should be in the same project and region
as the backups. The backups can only be restored in the
`destination_project`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The fully qualified name of the RestoreChannel.
`projects/*/locations/*/restoreChannels/*`

=item * C<< $msg->destination_project() >> / C<< $msg->destination_project($value) >>

Type: C<String>

Required. Immutable. The project into which the backups will be restored.
The format is `projects/{projectId}` or `projects/{projectNumber}`.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server generated global unique identifier of
[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) format.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this RestoreChannel was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp when this RestoreChannel was last updated.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Gkebackup::V1::RestoreChannel::RestoreChannel::LabelsEntry>)

Optional. A set of custom labels supplied by user.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User specified descriptive string for this RestoreChannel.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Output only. `etag` is used for optimistic concurrency control as a way to
help prevent simultaneous updates of a RestoreChannel from overwriting each
other. It is strongly suggested that systems make use of the 'etag' in the
read-modify-write cycle to perform RestoreChannel updates in order to
avoid race conditions: An `etag` is returned in the response to
`GetRestoreChannel`, and systems are expected to put that etag in the
request to `UpdateRestoreChannel` or `DeleteRestoreChannel` to
ensure that their change will be applied to the same version of the
resource.

=item * C<< $msg->destination_project_id() >> / C<< $msg->destination_project_id($value) >>

Type: C<String>

Output only. The project_id where backups will be restored.
Example Project ID: "my-project-id".
This will be an OUTPUT_ONLY field to return the project_id of the
destination project.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Gkebackup::V1::RestoreChannel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
