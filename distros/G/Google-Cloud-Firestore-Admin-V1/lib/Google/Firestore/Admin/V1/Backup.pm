package Google::Firestore::Admin::V1::Backup;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvZmlyZXN0b3JlL2FkbWluL3YxL2JhY2t1cC5wcm90bxIZZ29vZ2xlLmZpcmVz
dG9yZS5hZG1pbi52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLL
BQoGQmFja3VwEhcKBG5hbWUYASABKAlCA+BBA1IEbmFtZRJFCghkYXRhYmFzZRgCIAEoCUIp
4EED+kEjCiFmaXJlc3RvcmUuZ29vZ2xlYXBpcy5jb20vRGF0YWJhc2VSCGRhdGFiYXNlEiYK
DGRhdGFiYXNlX3VpZBgHIAEoCUID4EEDUgtkYXRhYmFzZVVpZBJECg1zbmFwc2hvdF90aW1l
GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgxzbmFwc2hvdFRpbWUS
QAoLZXhwaXJlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
CmV4cGlyZVRpbWUSQgoFc3RhdHMYBiABKAsyJy5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYx
LkJhY2t1cC5TdGF0c0ID4EEDUgVzdGF0cxJCCgVzdGF0ZRgIIAEoDjInLmdvb2dsZS5maXJl
c3RvcmUuYWRtaW4udjEuQmFja3VwLlN0YXRlQgPgQQNSBXN0YXRlGn0KBVN0YXRzEiIKCnNp
emVfYnl0ZXMYASABKANCA+BBA1IJc2l6ZUJ5dGVzEioKDmRvY3VtZW50X2NvdW50GAIgASgD
QgPgQQNSDWRvY3VtZW50Q291bnQSJAoLaW5kZXhfY291bnQYAyABKANCA+BBA1IKaW5kZXhD
b3VudCJKCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgwKCENSRUFUSU5HEAESCQoF
UkVBRFkQAhIRCg1OT1RfQVZBSUxBQkxFEAM6XupBWwofZmlyZXN0b3JlLmdvb2dsZWFwaXMu
Y29tL0JhY2t1cBI4cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Jh
Y2t1cHMve2JhY2t1cH1C2gEKHWNvbS5nb29nbGUuZmlyZXN0b3JlLmFkbWluLnYxQgtCYWNr
dXBQcm90b1ABWjljbG91ZC5nb29nbGUuY29tL2dvL2ZpcmVzdG9yZS9hcGl2MS9hZG1pbi9h
ZG1pbnBiO2FkbWlucGKiAgRHQ0ZTqgIfR29vZ2xlLkNsb3VkLkZpcmVzdG9yZS5BZG1pbi5W
McoCH0dvb2dsZVxDbG91ZFxGaXJlc3RvcmVcQWRtaW5cVjHqAiNHb29nbGU6OkNsb3VkOjpG
aXJlc3RvcmU6OkFkbWluOjpWMUqKHQoGEgQOAG8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAp
CggKAQgSAxYAPAoJCgIIJRIDFgA8CggKAQgSAxcAUAoJCgIICxIDFwBQCggKAQgSAxgAIgoJ
CgIIChIDGAAiCggKAQgSAxkALAoJCgIICBIDGQAsCggKAQgSAxoANgoJCgIIARIDGgA2CggK
AQgSAxsAIgoJCgIIJBIDGwAiCggKAQgSAxwAPQoJCgIIKRIDHAA9CggKAQgSAx0APAoJCgII
LRIDHQA8CqgBCgIEABIEIwBvARqbASBBIEJhY2t1cCBvZiBhIENsb3VkIEZpcmVzdG9yZSBE
YXRhYmFzZS4KCiBUaGUgYmFja3VwIGNvbnRhaW5zIGFsbCBkb2N1bWVudHMgYW5kIGluZGV4
IGNvbmZpZ3VyYXRpb25zIGZvciB0aGUgZ2l2ZW4KIGRhdGFiYXNlIGF0IGEgc3BlY2lmaWMg
cG9pbnQgaW4gdGltZS4KCgoKAwQAARIDIwgOCgsKAwQABxIEJAInBAoNCgUEAAedCBIEJAIn
BAorCgQEAAMAEgQqAjQDGh0gQmFja3VwIHNwZWNpZmljIHN0YXRpc3RpY3MuCgoMCgUEAAMA
ARIDKgoPCnkKBgQAAwACABIDLQRFGmogT3V0cHV0IG9ubHkuIFN1bW1hdGlvbiBvZiB0aGUg
c2l6ZSBvZiBhbGwgZG9jdW1lbnRzIGFuZCBpbmRleCBlbnRyaWVzIGluCiB0aGUgYmFja3Vw
LCBtZWFzdXJlZCBpbiBieXRlcy4KCg4KBwQAAwACAAUSAy0ECQoOCgcEAAMAAgABEgMtChQK
DgoHBAADAAIAAxIDLRcYCg4KBwQAAwACAAgSAy0ZRAoRCgoEAAMAAgAInAgAEgMtGkMKVAoG
BAADAAIBEgMwBEkaRSBPdXRwdXQgb25seS4gVGhlIHRvdGFsIG51bWJlciBvZiBkb2N1bWVu
dHMgY29udGFpbmVkIGluIHRoZSBiYWNrdXAuCgoOCgcEAAMAAgEFEgMwBAkKDgoHBAADAAIB
ARIDMAoYCg4KBwQAAwACAQMSAzAbHAoOCgcEAAMAAgEIEgMwHUgKEQoKBAADAAIBCJwIABID
MB5HClgKBgQAAwACAhIDMwRGGkkgT3V0cHV0IG9ubHkuIFRoZSB0b3RhbCBudW1iZXIgb2Yg
aW5kZXggZW50cmllcyBjb250YWluZWQgaW4gdGhlIGJhY2t1cC4KCg4KBwQAAwACAgUSAzME
CQoOCgcEAAMAAgIBEgMzChUKDgoHBAADAAICAxIDMxgZCg4KBwQAAwACAggSAzMaRQoRCgoE
AAMAAgIInAgAEgMzG0QKOQoEBAAEABIENwJEAxorIEluZGljYXRlIHRoZSBjdXJyZW50IHN0
YXRlIG9mIHRoZSBiYWNrdXAuCgoMCgUEAAQAARIDNwcMCioKBgQABAACABIDOQQaGhsgVGhl
IHN0YXRlIGlzIHVuc3BlY2lmaWVkLgoKDgoHBAAEAAIAARIDOQQVCg4KBwQABAACAAISAzkY
GQp1CgYEAAQAAgESAz0EERpmIFRoZSBwZW5kaW5nIGJhY2t1cCBpcyBzdGlsbCBiZWluZyBj
cmVhdGVkLiBPcGVyYXRpb25zIG9uIHRoZQogYmFja3VwIHdpbGwgYmUgcmVqZWN0ZWQgaW4g
dGhpcyBzdGF0ZS4KCg4KBwQABAACAQESAz0EDAoOCgcEAAQAAgECEgM9DxAKOQoGBAAEAAIC
EgNABA4aKiBUaGUgYmFja3VwIGlzIGNvbXBsZXRlIGFuZCByZWFkeSB0byB1c2UuCgoOCgcE
AAQAAgIBEgNABAkKDgoHBAAEAAICAhIDQAwNCjwKBgQABAACAxIDQwQWGi0gVGhlIGJhY2t1
cCBpcyBub3QgYXZhaWxhYmxlIGF0IHRoaXMgbW9tZW50LgoKDgoHBAAEAAIDARIDQwQRCg4K
BwQABAACAwISA0MUFQqSAwoEBAACABIDTgI+GoQDIE91dHB1dCBvbmx5LiBUaGUgdW5pcXVl
IHJlc291cmNlIG5hbWUgb2YgdGhlIEJhY2t1cC4KCiBGb3JtYXQgaXMgYHByb2plY3RzL3tw
cm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9iYWNrdXBzL3tiYWNrdXB9YC4KCiBUaGUg
bG9jYXRpb24gaW4gdGhlIG5hbWUgd2lsbCBiZSB0aGUgU3RhbmRhcmQgTWFuYWdlZCBNdWx0
aS1SZWdpb24gKFNNTVIpCiBsb2NhdGlvbiAoZS5nLiBgdXNgKSBpZiB0aGUgYmFja3VwIHdh
cyBjcmVhdGVkIHdpdGggYW4gU01NUiBsb2NhdGlvbiwgb3IKIHRoZSBHb29nbGUgTWFuYWdl
ZCBNdWx0aS1SZWdpb24gKEdNTVIpIGxvY2F0aW9uIChlLmcuIGBuYW01YCkgaWYgdGhlIGJh
Y2t1cAogd2FzIGNyZWF0ZWQgd2l0aCBhIEdNTVIgbG9jYXRpb24uCgoMCgUEAAIABRIDTgII
CgwKBQQAAgABEgNOCQ0KDAoFBAACAAMSA04QEQoMCgUEAAIACBIDThI9Cg8KCAQAAgAInAgA
EgNOEzwKiwEKBAQAAgESBFMCWAQafSBPdXRwdXQgb25seS4gTmFtZSBvZiB0aGUgRmlyZXN0
b3JlIGRhdGFiYXNlIHRoYXQgdGhlIGJhY2t1cCBpcyBmcm9tLgoKIEZvcm1hdCBpcyBgcHJv
amVjdHMve3Byb2plY3R9L2RhdGFiYXNlcy97ZGF0YWJhc2V9YC4KCgwKBQQAAgEFEgNTAggK
DAoFBAACAQESA1MJEQoMCgUEAAIBAxIDUxQVCg0KBQQAAgEIEgRTFlgDCg8KCAQAAgEInAgA
EgNUBC0KDwoHBAACAQifCBIEVQRXBQprCgQEAAICEgNcAkYaXiBPdXRwdXQgb25seS4gVGhl
IHN5c3RlbS1nZW5lcmF0ZWQgVVVJRDQgZm9yIHRoZSBGaXJlc3RvcmUgZGF0YWJhc2UgdGhh
dCB0aGUKIGJhY2t1cCBpcyBmcm9tLgoKDAoFBAACAgUSA1wCCAoMCgUEAAICARIDXAkVCgwK
BQQAAgIDEgNcGBkKDAoFBAACAggSA1waRQoPCggEAAICCJwIABIDXBtECm0KBAQAAgMSBGAC
YTIaXyBPdXRwdXQgb25seS4gVGhlIGJhY2t1cCBjb250YWlucyBhbiBleHRlcm5hbGx5IGNv
bnNpc3RlbnQgY29weSBvZiB0aGUKIGRhdGFiYXNlIGF0IHRoaXMgdGltZS4KCgwKBQQAAgMG
EgNgAhsKDAoFBAACAwESA2AcKQoMCgUEAAIDAxIDYCwtCgwKBQQAAgMIEgNhBjEKDwoIBAAC
AwicCAASA2EHMApICgQEAAIEEgRkAmUyGjogT3V0cHV0IG9ubHkuIFRoZSB0aW1lc3RhbXAg
YXQgd2hpY2ggdGhpcyBiYWNrdXAgZXhwaXJlcy4KCgwKBQQAAgQGEgNkAhsKDAoFBAACBAES
A2QcJwoMCgUEAAIEAxIDZCorCgwKBQQAAgQIEgNlBjEKDwoIBAACBAicCAASA2UHMAq+AQoE
BAACBRIDawI+GrABIE91dHB1dCBvbmx5LiBTdGF0aXN0aWNzIGFib3V0IHRoZSBiYWNrdXAu
CgogVGhpcyBkYXRhIG9ubHkgYmVjb21lcyBhdmFpbGFibGUgYWZ0ZXIgdGhlIGJhY2t1cCBp
cyBmdWxseSBtYXRlcmlhbGl6ZWQgdG8KIHNlY29uZGFyeSBzdG9yYWdlLiBUaGlzIGZpZWxk
IHdpbGwgYmUgZW1wdHkgdGlsbCB0aGVuLgoKDAoFBAACBQYSA2sCBwoMCgUEAAIFARIDawgN
CgwKBQQAAgUDEgNrEBEKDAoFBAACBQgSA2sSPQoPCggEAAIFCJwIABIDaxM8CjwKBAQAAgYS
A24CPhovIE91dHB1dCBvbmx5LiBUaGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgYmFja3VwLgoK
DAoFBAACBgYSA24CBwoMCgUEAAIGARIDbggNCgwKBQQAAgYDEgNuEBEKDAoFBAACBggSA24S
PQoPCggEAAIGCJwIABIDbhM8YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firestore::Admin::V1::Backup::Backup ===
    # Fields for Backup
    # Field: name Type: 9 ()
    # Field: database Type: 9 ()
    # Field: database_uid Type: 9 ()
    # Field: snapshot_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: stats Type: 11 (.google.firestore.admin.v1.Backup.Stats)
    # Field: state Type: 14 (.google.firestore.admin.v1.Backup.State)

# Enum: Backup::State
our $Backup_STATE_UNSPECIFIED = 0;
our $Backup_CREATING = 1;
our $Backup_READY = 2;
our $Backup_NOT_AVAILABLE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firestore::Admin::V1::Backup - Compiled Protocol Buffers messages for google/firestore/admin/v1/backup.proto

=head1 SYNOPSIS

    use Google::Firestore::Admin::V1::Backup;

    my $msg = Google::Firestore::Admin::V1::Backup::Backup->new({
        name => $name,
        database => $database,
        database_uid => $database_uid,
        snapshot_time => $snapshot_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firestore::Admin::V1::Backup::Backup->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firestore/admin/v1/backup.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firestore::Admin::V1::Backup::Backup

A Backup of a Cloud Firestore Database.

The backup contains all documents and index configurations for the given
database at a specific point in time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The unique resource name of the Backup.

Format is `projects/{project}/locations/{location}/backups/{backup}`.

The location in the name will be the Standard Managed Multi-Region (SMMR)
location (e.g. `us`) if the backup was created with an SMMR location, or
the Google Managed Multi-Region (GMMR) location (e.g. `nam5`) if the backup
was created with a GMMR location.

=item * C<< $msg->database() >> / C<< $msg->database($value) >>

Type: C<String>

Output only. Name of the Firestore database that the backup is from.

Format is `projects/{project}/databases/{database}`.

=item * C<< $msg->database_uid() >> / C<< $msg->database_uid($value) >>

Type: C<String>

Output only. The system-generated UUID4 for the Firestore database that the
backup is from.

=item * C<< $msg->snapshot_time() >> / C<< $msg->snapshot_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The backup contains an externally consistent copy of the
database at this time.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The timestamp at which this backup expires.

=item * C<< $msg->stats() >> / C<< $msg->stats($value) >>

Type: C<Message> (L<Google::Firestore::Admin::V1::Backup::Backup::Stats>)

Output only. Statistics about the backup.

This data only becomes available after the backup is fully materialized to
secondary storage. This field will be empty till then.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Firestore::Admin::V1::Backup::State>)

Output only. The current state of the backup.

=back

=head3 Enum: Backup::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<READY> => C<2>

=item * C<NOT_AVAILABLE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firestore::Admin::V1::Backup::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
