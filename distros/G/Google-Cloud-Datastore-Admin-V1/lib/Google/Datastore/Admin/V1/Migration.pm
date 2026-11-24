package Google::Datastore::Admin::V1::Migration;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvZGF0YXN0b3JlL2FkbWluL3YxL21pZ3JhdGlvbi5wcm90bxIZZ29vZ2xlLmRh
dGFzdG9yZS5hZG1pbi52MSJWChNNaWdyYXRpb25TdGF0ZUV2ZW50Ej8KBXN0YXRlGAEgASgO
MikuZ29vZ2xlLmRhdGFzdG9yZS5hZG1pbi52MS5NaWdyYXRpb25TdGF0ZVIFc3RhdGUi+wUK
Fk1pZ3JhdGlvblByb2dyZXNzRXZlbnQSPAoEc3RlcBgBIAEoDjIoLmdvb2dsZS5kYXRhc3Rv
cmUuYWRtaW4udjEuTWlncmF0aW9uU3RlcFIEc3RlcBJ4ChRwcmVwYXJlX3N0ZXBfZGV0YWls
cxgCIAEoCzJELmdvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjEuTWlncmF0aW9uUHJvZ3Jlc3NF
dmVudC5QcmVwYXJlU3RlcERldGFpbHNIAFIScHJlcGFyZVN0ZXBEZXRhaWxzEo4BChxyZWRp
cmVjdF93cml0ZXNfc3RlcF9kZXRhaWxzGAMgASgLMksuZ29vZ2xlLmRhdGFzdG9yZS5hZG1p
bi52MS5NaWdyYXRpb25Qcm9ncmVzc0V2ZW50LlJlZGlyZWN0V3JpdGVzU3RlcERldGFpbHNI
AFIZcmVkaXJlY3RXcml0ZXNTdGVwRGV0YWlscxqCAQoSUHJlcGFyZVN0ZXBEZXRhaWxzEmwK
EGNvbmN1cnJlbmN5X21vZGUYASABKA4yQS5nb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxLk1p
Z3JhdGlvblByb2dyZXNzRXZlbnQuQ29uY3VycmVuY3lNb2RlUg9jb25jdXJyZW5jeU1vZGUa
iQEKGVJlZGlyZWN0V3JpdGVzU3RlcERldGFpbHMSbAoQY29uY3VycmVuY3lfbW9kZRgBIAEo
DjJBLmdvb2dsZS5kYXRhc3RvcmUuYWRtaW4udjEuTWlncmF0aW9uUHJvZ3Jlc3NFdmVudC5D
b25jdXJyZW5jeU1vZGVSD2NvbmN1cnJlbmN5TW9kZSJ3Cg9Db25jdXJyZW5jeU1vZGUSIAoc
Q09OQ1VSUkVOQ1lfTU9ERV9VTlNQRUNJRklFRBAAEg8KC1BFU1NJTUlTVElDEAESDgoKT1BU
SU1JU1RJQxACEiEKHU9QVElNSVNUSUNfV0lUSF9FTlRJVFlfR1JPVVBTEANCDgoMc3RlcF9k
ZXRhaWxzKlgKDk1pZ3JhdGlvblN0YXRlEh8KG01JR1JBVElPTl9TVEFURV9VTlNQRUNJRklF
RBAAEgsKB1JVTk5JTkcQARIKCgZQQVVTRUQQAhIMCghDT01QTEVURRADKuMBCg1NaWdyYXRp
b25TdGVwEh4KGk1JR1JBVElPTl9TVEVQX1VOU1BFQ0lGSUVEEAASCwoHUFJFUEFSRRAGEgkK
BVNUQVJUEAESHgoaQVBQTFlfV1JJVEVTX1NZTkNIUk9OT1VTTFkQBxITCg9DT1BZX0FORF9W
RVJJRlkQAhIoCiRSRURJUkVDVF9FVkVOVFVBTExZX0NPTlNJU1RFTlRfUkVBRFMQAxImCiJS
RURJUkVDVF9TVFJPTkdMWV9DT05TSVNURU5UX1JFQURTEAQSEwoPUkVESVJFQ1RfV1JJVEVT
EAVC1gEKHWNvbS5nb29nbGUuZGF0YXN0b3JlLmFkbWluLnYxQg5NaWdyYXRpb25Qcm90b1AB
WjljbG91ZC5nb29nbGUuY29tL2dvL2RhdGFzdG9yZS9hZG1pbi9hcGl2MS9hZG1pbnBiO2Fk
bWlucGKqAh9Hb29nbGUuQ2xvdWQuRGF0YXN0b3JlLkFkbWluLlYxygIfR29vZ2xlXENsb3Vk
XERhdGFzdG9yZVxBZG1pblxWMeoCI0dvb2dsZTo6Q2xvdWQ6OkRhdGFzdG9yZTo6QWRtaW46
OlYxSp4cCgYSBA4AewEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQACIKCAoBCBIDEgA8CgkKAgglEgMSADwKCAoBCBIDEwBQCgkKAggLEgMTAFAKCAoBCBID
FAAiCgkKAggKEgMUACIKCAoBCBIDFQAvCgkKAggIEgMVAC8KCAoBCBIDFgA2CgkKAggBEgMW
ADYKCAoBCBIDFwA9CgkKAggpEgMXAD0KCAoBCBIDGAA8CgkKAggtEgMYADwKwAEKAgQAEgQd
ACABGrMBIEFuIGV2ZW50IHNpZ25pZnlpbmcgYSBjaGFuZ2UgaW4gc3RhdGUgb2YgYSBbbWln
cmF0aW9uIGZyb20gQ2xvdWQgRGF0YXN0b3JlIHRvCiBDbG91ZCBGaXJlc3RvcmUgaW4gRGF0
YXN0b3JlCiBtb2RlXShodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vZGF0YXN0b3JlL2RvY3Mv
dXBncmFkZS10by1maXJlc3RvcmUpLgoKCgoDBAABEgMdCBsKLgoEBAACABIDHwIbGiEgVGhl
IG5ldyBzdGF0ZSBvZiB0aGUgbWlncmF0aW9uLgoKDAoFBAACAAYSAx8CEAoMCgUEAAIAARID
HxEWCgwKBQQAAgADEgMfGRoKxgEKAgQBEgQlAFABGrkBIEFuIGV2ZW50IHNpZ25pZnlpbmcg
dGhlIHN0YXJ0IG9mIGEgbmV3IHN0ZXAgaW4gYSBbbWlncmF0aW9uIGZyb20gQ2xvdWQKIERh
dGFzdG9yZSB0byBDbG91ZCBGaXJlc3RvcmUgaW4gRGF0YXN0b3JlCiBtb2RlXShodHRwczov
L2Nsb3VkLmdvb2dsZS5jb20vZGF0YXN0b3JlL2RvY3MvdXBncmFkZS10by1maXJlc3RvcmUp
LgoKCgoDBAEBEgMlCB4KRgoEBAEEABIEJwIzAxo4IENvbmN1cnJlbmN5IG1vZGVzIGZvciB0
cmFuc2FjdGlvbnMgaW4gQ2xvdWQgRmlyZXN0b3JlLgoKDAoFBAEEAAESAycHFgodCgYEAQQA
AgASAykEJRoOIFVuc3BlY2lmaWVkLgoKDgoHBAEEAAIAARIDKQQgCg4KBwQBBAACAAISAykj
JAopCgYEAQQAAgESAywEFBoaIFBlc3NpbWlzdGljIGNvbmN1cnJlbmN5LgoKDgoHBAEEAAIB
ARIDLAQPCg4KBwQBBAACAQISAywSEwooCgYEAQQAAgISAy8EExoZIE9wdGltaXN0aWMgY29u
Y3VycmVuY3kuCgoOCgcEAQQAAgIBEgMvBA4KDgoHBAEEAAICAhIDLxESCjsKBgQBBAACAxID
MgQmGiwgT3B0aW1pc3RpYyBjb25jdXJyZW5jeSB3aXRoIGVudGl0eSBncm91cHMuCgoOCgcE
AQQAAgMBEgMyBCEKDgoHBAEEAAIDAhIDMiQlCi8KBAQBAwASBDYCOgMaISBEZXRhaWxzIGZv
ciB0aGUgYFBSRVBBUkVgIHN0ZXAuCgoMCgUEAQMAARIDNgocCmkKBgQBAwACABIDOQQpGlog
VGhlIGNvbmN1cnJlbmN5IG1vZGUgdGhpcyBkYXRhYmFzZSB3aWxsIHVzZSB3aGVuIGl0IHJl
YWNoZXMgdGhlCiBgUkVESVJFQ1RfV1JJVEVTYCBzdGVwLgoKDgoHBAEDAAIABhIDOQQTCg4K
BwQBAwACAAESAzkUJAoOCgcEAQMAAgADEgM5JygKNwoEBAEDARIEPQJAAxopIERldGFpbHMg
Zm9yIHRoZSBgUkVESVJFQ1RfV1JJVEVTYCBzdGVwLgoKDAoFBAEDAQESAz0KIwo4CgYEAQMB
AgASAz8EKRopIFRocyBjb25jdXJyZW5jeSBtb2RlIGZvciB0aGlzIGRhdGFiYXNlLgoKDgoH
BAEDAQIABhIDPwQTCg4KBwQBAwECAAESAz8UJAoOCgcEAQMBAgADEgM/JygKpwEKBAQBAgAS
A0YCGRqZASBUaGUgc3RlcCB0aGF0IGlzIHN0YXJ0aW5nLgoKIEFuIGV2ZW50IHdpdGggc3Rl
cCBzZXQgdG8gYFNUQVJUYCBpbmRpY2F0ZXMgdGhhdCB0aGUgbWlncmF0aW9uCiBoYXMgYmVl
biByZXZlcnRlZCBiYWNrIHRvIHRoZSBpbml0aWFsIHByZS1taWdyYXRpb24gc3RhdGUuCgoM
CgUEAQIABhIDRgIPCgwKBQQBAgABEgNGEBQKDAoFBAECAAMSA0YXGAooCgQEAQgAEgRJAk8D
GhogRGV0YWlscyBhYm91dCB0aGlzIHN0ZXAuCgoMCgUEAQgAARIDSQgUCi4KBAQBAgESA0sE
MBohIERldGFpbHMgZm9yIHRoZSBgUFJFUEFSRWAgc3RlcC4KCgwKBQQBAgEGEgNLBBYKDAoF
BAECAQESA0sXKwoMCgUEAQIBAxIDSy4vCjYKBAQBAgISA04EPxopIERldGFpbHMgZm9yIHRo
ZSBgUkVESVJFQ1RfV1JJVEVTYCBzdGVwLgoKDAoFBAECAgYSA04EHQoMCgUEAQICARIDTh46
CgwKBQQBAgIDEgNOPT4KJQoCBQASBFMAXwEaGSBTdGF0ZXMgZm9yIGEgbWlncmF0aW9uLgoK
CgoDBQABEgNTBRMKGwoEBQACABIDVQIiGg4gVW5zcGVjaWZpZWQuCgoMCgUFAAIAARIDVQId
CgwKBQUAAgACEgNVICEKKAoEBQACARIDWAIOGhsgVGhlIG1pZ3JhdGlvbiBpcyBydW5uaW5n
LgoKDAoFBQACAQESA1gCCQoMCgUFAAIBAhIDWAwNCicKBAUAAgISA1sCDRoaIFRoZSBtaWdy
YXRpb24gaXMgcGF1c2VkLgoKDAoFBQACAgESA1sCCAoMCgUFAAICAhIDWwsMCikKBAUAAgMS
A14CDxocIFRoZSBtaWdyYXRpb24gaXMgY29tcGxldGUuCgoMCgUFAAIDARIDXgIKCgwKBQUA
AgMCEgNeDQ4KIwoCBQESBGIAewEaFyBTdGVwcyBpbiBhIG1pZ3JhdGlvbi4KCgoKAwUBARID
YgUSChsKBAUBAgASA2QCIRoOIFVuc3BlY2lmaWVkLgoKDAoFBQECAAESA2QCHAoMCgUFAQIA
AhIDZB8gCkUKBAUBAgESA2cCDho4IFByZS1taWdyYXRpb246IHRoZSBkYXRhYmFzZSBpcyBw
cmVwYXJlZCBmb3IgbWlncmF0aW9uLgoKDAoFBQECAQESA2cCCQoMCgUFAQIBAhIDZwwNCiIK
BAUBAgISA2oCDBoVIFN0YXJ0IG9mIG1pZ3JhdGlvbi4KCgwKBQUBAgIBEgNqAgcKDAoFBQEC
AgISA2oKCwpICgQFAQIDEgNtAiEaOyBXcml0ZXMgYXJlIGFwcGxpZWQgc3luY2hyb25vdXNs
eSB0byBhdCBsZWFzdCBvbmUgcmVwbGljYS4KCgwKBQUBAgMBEgNtAhwKDAoFBQECAwISA20f
IAppCgQFAQIEEgNxAhYaXCBEYXRhIGlzIGNvcGllZCB0byBDbG91ZCBGaXJlc3RvcmUgYW5k
IHRoZW4gdmVyaWZpZWQgdG8gbWF0Y2ggdGhlIGRhdGEgaW4KIENsb3VkIERhdGFzdG9yZS4K
CgwKBQUBAgQBEgNxAhEKDAoFBQECBAISA3EUFQpNCgQFAQIFEgN0AisaQCBFdmVudHVhbGx5
LWNvbnNpc3RlbnQgcmVhZHMgYXJlIHJlZGlyZWN0ZWQgdG8gQ2xvdWQgRmlyZXN0b3JlLgoK
DAoFBQECBQESA3QCJgoMCgUFAQIFAhIDdCkqCksKBAUBAgYSA3cCKRo+IFN0cm9uZ2x5LWNv
bnNpc3RlbnQgcmVhZHMgYXJlIHJlZGlyZWN0ZWQgdG8gQ2xvdWQgRmlyZXN0b3JlLgoKDAoF
BQECBgESA3cCJAoMCgUFAQIGAhIDdycoCjgKBAUBAgcSA3oCFhorIFdyaXRlcyBhcmUgcmVk
aXJlY3RlZCB0byBDbG91ZCBGaXJlc3RvcmUuCgoMCgUFAQIHARIDegIRCgwKBQUBAgcCEgN6
FBViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Datastore::Admin::V1::Migration::MigrationStateEvent ===
    # Fields for MigrationStateEvent
    # Field: state Type: 14 (.google.datastore.admin.v1.MigrationState)

# === Message: Google::Datastore::Admin::V1::Migration::MigrationProgressEvent ===
    # Fields for MigrationProgressEvent
    # Field: step Type: 14 (.google.datastore.admin.v1.MigrationStep)
    # Field: prepare_step_details Type: 11 (.google.datastore.admin.v1.MigrationProgressEvent.PrepareStepDetails)
    # Field: redirect_writes_step_details Type: 11 (.google.datastore.admin.v1.MigrationProgressEvent.RedirectWritesStepDetails)

# Enum: MigrationProgressEvent::ConcurrencyMode
our $MigrationProgressEvent_CONCURRENCY_MODE_UNSPECIFIED = 0;
our $MigrationProgressEvent_PESSIMISTIC = 1;
our $MigrationProgressEvent_OPTIMISTIC = 2;
our $MigrationProgressEvent_OPTIMISTIC_WITH_ENTITY_GROUPS = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Datastore::Admin::V1::Migration - Compiled Protocol Buffers messages for google/datastore/admin/v1/migration.proto

=head1 SYNOPSIS

    use Google::Datastore::Admin::V1::Migration;

    my $msg = Google::Datastore::Admin::V1::Migration::MigrationStateEvent->new({
        state => $state,
    });

    # Read or update a field
    my $val = $msg->state();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Datastore::Admin::V1::Migration::MigrationStateEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/datastore/admin/v1/migration.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Datastore::Admin::V1::Migration::MigrationStateEvent

An event signifying a change in state of a [migration from Cloud Datastore to
Cloud Firestore in Datastore
mode](https://cloud.google.com/datastore/docs/upgrade-to-firestore).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Datastore::Admin::V1::MigrationState>)

The new state of the migration.

=back

=head2 Google::Datastore::Admin::V1::Migration::MigrationProgressEvent

An event signifying the start of a new step in a [migration from Cloud
Datastore to Cloud Firestore in Datastore
mode](https://cloud.google.com/datastore/docs/upgrade-to-firestore).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->step() >> / C<< $msg->step($value) >>

Type: C<Enum> (L<Google::Datastore::Admin::V1::MigrationStep>)

The step that is starting.

An event with step set to `START` indicates that the migration
has been reverted back to the initial pre-migration state.

=item * C<< $msg->prepare_step_details() >> / C<< $msg->prepare_step_details($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1::Migration::MigrationProgressEvent::PrepareStepDetails>)

Details for the `PREPARE` step.

=item * C<< $msg->redirect_writes_step_details() >> / C<< $msg->redirect_writes_step_details($value) >>

Type: C<Message> (L<Google::Datastore::Admin::V1::Migration::MigrationProgressEvent::RedirectWritesStepDetails>)

Details for the `REDIRECT_WRITES` step.

=back

=head3 Enum: MigrationProgressEvent::ConcurrencyMode

=over 4

=item * C<CONCURRENCY_MODE_UNSPECIFIED> => C<0>

=item * C<PESSIMISTIC> => C<1>

=item * C<OPTIMISTIC> => C<2>

=item * C<OPTIMISTIC_WITH_ENTITY_GROUPS> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Datastore::Admin::V1::Migration::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
